#!/usr/bin/env bash
# Purpose: Test the functionality of package manager wrappers created by create-package-blockers.sh
# This script tests various input formats for sudo apt install commands to ensure proper handling by the wrappers.

# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/log_utils.sh"

# Exit on error
set -e

# Define test cases with expected outcomes
TEST_CASES=(
  "sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager -y|success"
  "sudo apt -y install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager|success"
  "sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager|success"
  "sudo apt install -y qemu-kvm libvirt-daemon-system|success"
  "sudo apt --yes install qemu-kvm libvirt-daemon-system libvirt-clients|success"
  "sudo apt-get install qemu-kvm libvirt-daemon-system -y|success"
  "sudo apt-get -y install bridge-utils virt-manager|success"
  "sudo apt install python3 python3-pip -y|blocked"  # Test blocked packages
  "sudo apt -y install nodejs npm|blocked"  # Test blocked packages
  "sudo apt install vim curl -y|success"  # Test non-blocked packages
)

# Function to run a single test
run_test() {
  local test_case="$1"
  IFS='|' read -r command expected <<< "$test_case"
  log_info "Testing command: $command"
  log_info "Expected outcome: $expected"
  log_info "Executing: $command"
  if $command; then
    if [[ "$expected" == "success" ]]; then
      log_success "Command executed successfully as expected: $command"
      return 0
    else
      log_error "Command succeeded unexpectedly (expected blocking): $command"
      return 1
    fi
  else
    if [[ "$expected" == "blocked" ]]; then
      log_success "Command was blocked as expected: $command"
      return 0
    else
      log_error "Command failed unexpectedly (expected success): $command"
      return 1
    fi
  fi
  log_info "------------------------"
  return 0
}

# Main test execution
log_info "Starting tests for package manager wrappers..."

FAILED=0
for case in "${TEST_CASES[@]}"; do
  if ! run_test "$case"; then
    FAILED=1
  fi
done

if [[ $FAILED -eq 1 ]]; then
  log_error "Some tests failed. Check the output for details."
  exit 1
else
  log_success "All tests passed successfully!"
  exit 0
fi 