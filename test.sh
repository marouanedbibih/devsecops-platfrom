#!/bin/bash

# DevSecOps Platform - Test Script
# This script validates the infrastructure components and platform health
# Usage: ./scripts/test.sh [OPTIONS]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KUBECTL_TIMEOUT=60
HEALTH_CHECK_TIMEOUT=30

# Default values
VERBOSE=false
QUICK_MODE=false
SKIP_CONNECTIVITY=false
NAMESPACE_FILTER=""

# Platform endpoints
declare -A PLATFORM_ENDPOINTS=(
    ["jenkins"]="jenkins.marouanedbibih.studio"
    ["harbor"]="harbor.marouanedbibih.studio"
    ["sonarqube"]="sonarqube.marouanedbibih.studio"
    ["consul"]="consul.marouanedbibih.studio"
    ["minio"]="minio.marouanedbibih.studio"
    ["longhorn"]="longhorn.marouanedbibih.studio"
    ["rancher"]="rancher.marouanedbibih.engineer"
)

# Namespaces to check
declare -A PLATFORM_NAMESPACES=(
    ["jenkins"]="jenkins"
    ["harbor"]="harbor"
    ["sonar"]="sonar"
    ["consul"]="consul"
    ["minio"]="minio"
    ["longhorn-system"]="longhorn-system"
    ["cattle-system"]="cattle-system"
    ["vault"]="vault"
    ["keycloak"]="keycloak"
    ["cert-manager"]="cert-manager"
    ["ingress-nginx"]="ingress-nginx"
)

# Functions
print_header() {
    echo -e "${BLUE}================================"
    echo -e "  DevSecOps Platform Test Suite"
    echo -e "================================${NC}"
    echo ""
}

print_section() {
    echo -e "${YELLOW}📋 $1${NC}"
    echo "---"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_usage() {
    cat << EOF
DevSecOps Platform Test Script

USAGE:
    ./scripts/test.sh [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -q, --quick             Run quick tests only (skip heavy checks)
    -s, --skip-connectivity Skip connectivity tests
    -n, --namespace NAME    Test specific namespace only
    --dry-run              Show what would be tested without running

EXAMPLES:
    ./scripts/test.sh                    # Run all tests
    ./scripts/test.sh -v                 # Verbose output
    ./scripts/test.sh -q                 # Quick tests only
    ./scripts/test.sh -n jenkins         # Test jenkins namespace only
    ./scripts/test.sh --skip-connectivity # Skip external connectivity tests

EOF
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local errors=0
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        ((errors++))
    else
        print_success "kubectl is available"
        if $VERBOSE; then
            kubectl version --client --short 2>/dev/null || true
        fi
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed or not in PATH"
        ((errors++))
    else
        print_success "helm is available"
        if $VERBOSE; then
            helm version --short 2>/dev/null || true
        fi
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed or not in PATH"
        ((errors++))
    else
        print_success "curl is available"
    fi
    
    # Check kubernetes connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        ((errors++))
    else
        print_success "Kubernetes cluster is accessible"
        if $VERBOSE; then
            kubectl cluster-info
        fi
    fi
    
    echo ""
    return $errors
}

test_namespace_health() {
    local namespace=$1
    local service_name=$2
    
    print_info "Testing namespace: $namespace"
    
    # Check if namespace exists
    if ! kubectl get namespace "$namespace" &> /dev/null; then
        print_error "Namespace '$namespace' does not exist"
        return 1
    fi
    
    # Check pods status
    local not_ready_pods
    not_ready_pods=$(kubectl get pods -n "$namespace" --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
    
    if [ "$not_ready_pods" -gt 0 ]; then
        print_warning "$not_ready_pods pods are not in Running state in namespace '$namespace'"
        if $VERBOSE; then
            kubectl get pods -n "$namespace" --field-selector=status.phase!=Running
        fi
    else
        print_success "All pods are running in namespace '$namespace'"
    fi
    
    # Check services
    local services_count
    services_count=$(kubectl get services -n "$namespace" --no-headers 2>/dev/null | wc -l)
    
    if [ "$services_count" -gt 0 ]; then
        print_success "$services_count services found in namespace '$namespace'"
    else
        print_warning "No services found in namespace '$namespace'"
    fi
    
    # Check persistent volumes (if any)
    local pvc_count
    pvc_count=$(kubectl get pvc -n "$namespace" --no-headers 2>/dev/null | wc -l)
    
    if [ "$pvc_count" -gt 0 ]; then
        local bound_pvc
        bound_pvc=$(kubectl get pvc -n "$namespace" --field-selector=status.phase=Bound --no-headers 2>/dev/null | wc -l)
        if [ "$bound_pvc" -eq "$pvc_count" ]; then
            print_success "All $pvc_count PVCs are bound in namespace '$namespace'"
        else
            print_warning "$(($pvc_count - $bound_pvc)) PVCs are not bound in namespace '$namespace'"
        fi
    fi
    
    return 0
}

test_platform_namespaces() {
    print_section "Testing Platform Namespaces"
    
    local failed_namespaces=0
    
    for service_name in "${!PLATFORM_NAMESPACES[@]}"; do
        local namespace="${PLATFORM_NAMESPACES[$service_name]}"
        
        # Skip if namespace filter is set and doesn't match
        if [[ -n "$NAMESPACE_FILTER" && "$namespace" != "$NAMESPACE_FILTER" ]]; then
            continue
        fi
        
        if ! test_namespace_health "$namespace" "$service_name"; then
            ((failed_namespaces++))
        fi
        echo ""
    done
    
    if [ $failed_namespaces -eq 0 ]; then
        print_success "All platform namespaces are healthy"
    else
        print_error "$failed_namespaces namespace(s) have issues"
    fi
    
    echo ""
    return $failed_namespaces
}

test_ingress_connectivity() {
    if $SKIP_CONNECTIVITY; then
        print_info "Skipping connectivity tests (--skip-connectivity flag)"
        return 0
    fi
    
    print_section "Testing Ingress Connectivity"
    
    local failed_endpoints=0
    
    for service in "${!PLATFORM_ENDPOINTS[@]}"; do
        local endpoint="${PLATFORM_ENDPOINTS[$service]}"
        local url="https://$endpoint"
        
        print_info "Testing $service at $url"
        
        # Test with timeout and follow redirects
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $HEALTH_CHECK_TIMEOUT --max-time $HEALTH_CHECK_TIMEOUT "$url" || echo "000")
        
        case $http_code in
            200|301|302|401|403)
                print_success "$service is accessible (HTTP $http_code)"
                ;;
            000)
                print_error "$service is not accessible (connection failed)"
                ((failed_endpoints++))
                ;;
            *)
                print_warning "$service returned HTTP $http_code"
                ;;
        esac
    done
    
    echo ""
    
    if [ $failed_endpoints -eq 0 ]; then
        print_success "All endpoints are accessible"
    else
        print_error "$failed_endpoints endpoint(s) are not accessible"
    fi
    
    echo ""
    return $failed_endpoints
}

test_storage_classes() {
    print_section "Testing Storage Classes"
    
    # Check if storage classes exist
    local storage_classes
    storage_classes=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
    
    if [ "$storage_classes" -gt 0 ]; then
        print_success "$storage_classes storage class(es) available"
        
        if $VERBOSE; then
            kubectl get storageclass
        fi
        
        # Check for longhorn storage class specifically
        if kubectl get storageclass longhorn &> /dev/null; then
            print_success "Longhorn storage class is available"
        else
            print_warning "Longhorn storage class not found"
        fi
    else
        print_error "No storage classes found"
        return 1
    fi
    
    echo ""
    return 0
}

test_ingress_controllers() {
    print_section "Testing Ingress Controllers"
    
    # Check NGINX Ingress Controller
    if kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx &> /dev/null; then
        local nginx_pods
        nginx_pods=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running --no-headers | wc -l)
        
        if [ "$nginx_pods" -gt 0 ]; then
            print_success "NGINX Ingress Controller is running ($nginx_pods pod(s))"
        else
            print_error "NGINX Ingress Controller pods are not running"
            return 1
        fi
    else
        print_error "NGINX Ingress Controller not found"
        return 1
    fi
    
    # Check ingress resources
    local ingress_count
    ingress_count=$(kubectl get ingress --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [ "$ingress_count" -gt 0 ]; then
        print_success "$ingress_count ingress resource(s) configured"
    else
        print_warning "No ingress resources found"
    fi
    
    echo ""
    return 0
}

test_cert_manager() {
    print_section "Testing Certificate Management"
    
    # Check cert-manager
    if kubectl get pods -n cert-manager &> /dev/null; then
        local cert_manager_pods
        cert_manager_pods=$(kubectl get pods -n cert-manager --field-selector=status.phase=Running --no-headers | wc -l)
        
        if [ "$cert_manager_pods" -ge 3 ]; then
            print_success "cert-manager is running ($cert_manager_pods pod(s))"
        else
            print_warning "cert-manager may not be fully operational ($cert_manager_pods pod(s) running)"
        fi
    else
        print_error "cert-manager not found"
        return 1
    fi
    
    # Check cluster issuers
    local cluster_issuers
    cluster_issuers=$(kubectl get clusterissuer --no-headers 2>/dev/null | wc -l)
    
    if [ "$cluster_issuers" -gt 0 ]; then
        print_success "$cluster_issuers cluster issuer(s) configured"
        
        if $VERBOSE; then
            kubectl get clusterissuer
        fi
    else
        print_warning "No cluster issuers found"
    fi
    
    # Check certificates
    local certificates
    certificates=$(kubectl get certificates --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [ "$certificates" -gt 0 ]; then
        print_success "$certificates certificate(s) managed"
    else
        print_warning "No certificates found"
    fi
    
    echo ""
    return 0
}

test_helm_releases() {
    print_section "Testing Helm Releases"
    
    local failed_releases=0
    
    # Get all helm releases across all namespaces
    local releases
    releases=$(helm list --all-namespaces --output json 2>/dev/null)
    
    if [ "$releases" != "[]" ]; then
        local release_count
        release_count=$(echo "$releases" | jq length)
        print_success "$release_count Helm release(s) found"
        
        # Check each release status
        while IFS= read -r release; do
            local name status namespace
            name=$(echo "$release" | jq -r '.name')
            status=$(echo "$release" | jq -r '.status')
            namespace=$(echo "$release" | jq -r '.namespace')
            
            if [ "$status" = "deployed" ]; then
                print_success "Release '$name' in namespace '$namespace' is deployed"
            else
                print_error "Release '$name' in namespace '$namespace' has status: $status"
                ((failed_releases++))
            fi
        done < <(echo "$releases" | jq -c '.[]')
        
    else
        print_warning "No Helm releases found"
    fi
    
    echo ""
    return $failed_releases
}

run_performance_tests() {
    if $QUICK_MODE; then
        print_info "Skipping performance tests (quick mode)"
        return 0
    fi
    
    print_section "Running Performance Tests"
    
    # Test cluster resource usage
    print_info "Checking cluster resource usage..."
    
    local node_count
    node_count=$(kubectl get nodes --no-headers | wc -l)
    print_info "Cluster has $node_count node(s)"
    
    if $VERBOSE; then
        kubectl top nodes 2>/dev/null || print_warning "Metrics server not available for node metrics"
        echo ""
        kubectl top pods --all-namespaces --sort-by=cpu 2>/dev/null | head -10 || print_warning "Metrics server not available for pod metrics"
    fi
    
    echo ""
    return 0
}

generate_test_report() {
    local exit_code=$1
    
    print_section "Test Summary"
    
    if [ $exit_code -eq 0 ]; then
        print_success "All tests passed! DevSecOps platform is healthy ✨"
    else
        print_error "Some tests failed. Please review the output above."
        print_info "Common troubleshooting steps:"
        echo "  1. Check pod logs: kubectl logs -n <namespace> <pod-name>"
        echo "  2. Describe failed resources: kubectl describe <resource> -n <namespace>"
        echo "  3. Check ingress configuration: kubectl get ingress --all-namespaces"
        echo "  4. Verify DNS resolution: nslookup <endpoint>"
    fi
    
    echo ""
    print_info "Test completed at $(date)"
    echo ""
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quick)
                QUICK_MODE=true
                shift
                ;;
            -s|--skip-connectivity)
                SKIP_CONNECTIVITY=true
                shift
                ;;
            -n|--namespace)
                NAMESPACE_FILTER="$2"
                shift 2
                ;;
            --dry-run)
                echo "Dry run mode - would test the following:"
                echo "✓ Prerequisites check"
                echo "✓ Platform namespaces: ${!PLATFORM_NAMESPACES[*]}"
                echo "✓ Ingress connectivity: ${!PLATFORM_ENDPOINTS[*]}"
                echo "✓ Storage classes"
                echo "✓ Ingress controllers"
                echo "✓ Certificate management"
                echo "✓ Helm releases"
                if ! $QUICK_MODE; then
                    echo "✓ Performance tests"
                fi
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_header
    
    local total_errors=0
    
    # Run tests
    check_prerequisites || ((total_errors++))
    test_platform_namespaces || ((total_errors++))
    test_ingress_connectivity || ((total_errors++))
    test_storage_classes || ((total_errors++))
    test_ingress_controllers || ((total_errors++))
    test_cert_manager || ((total_errors++))
    test_helm_releases || ((total_errors++))
    run_performance_tests || ((total_errors++))
    
    generate_test_report $total_errors
    
    exit $total_errors
}

# Run main function with all arguments
main "$@"
