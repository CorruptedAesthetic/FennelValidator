#!/bin/bash
# Helper script to connect to cloud instances

echo "Cloud Instance Connection Helper"
echo "======================================"
echo

# You'll need to update these with your actual instance IPs and SSH key
echo "Available instances:"
echo "1. fennel-validator-x86-1751682420"
echo "2. fennel-validator-x86-1751682235"
echo

echo "To connect, use:"
echo "ssh -i /path/to/your/ssh-key ubuntu@<INSTANCE_PUBLIC_IP>"
echo

echo "Instance IPs (get from your cloud provider console):"
echo "- Check: Compute > Instances > [Select Instance] > Public IP"
