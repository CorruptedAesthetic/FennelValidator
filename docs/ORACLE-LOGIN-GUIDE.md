# 🌐 Oracle Cloud Validator Login Guide

This guide shows you how to connect to your FennelValidator running on Oracle Cloud Infrastructure (OCI).

## 📋 **Prerequisites**

- Oracle CLI installed and configured
- SSH key pair for your instance
- Instance OCID (Oracle Cloud Identifier)

## 🔍 **Step 1: Get Current Instance Information**

Your instance IP address may change when restarted, so always check the current details first:

### **Get Instance Status**
```bash
oci compute instance get --instance-id YOUR_INSTANCE_OCID --query 'data.{state:"lifecycle-state",name:"display-name"}' --output table
```

### **Get Current IP Address**
```bash
oci compute instance list-vnics --instance-id YOUR_INSTANCE_OCID --query 'data[0].{"Public-IP":"public-ip","Private-IP":"private-ip","State":"lifecycle-state"}' --output table
```

## 🔑 **Step 2: Connect via SSH**

### **For Oracle Linux Instances (ol9)**
```bash
ssh -i ~/.ssh/oracle_fennel_key opc@CURRENT_PUBLIC_IP
```

### **For Ubuntu Instances**
```bash
ssh -i ~/.ssh/oracle_fennel_key ubuntu@CURRENT_PUBLIC_IP
```

## 📝 **Your Instance Details**

### **Instance Information**
- **Name**: `slowblock-validator-ol9`
- **OCID**: `ocid1.instance.oc1.iad.anuwcljtwd4qh7ickcucoeximyxua4ebuv33ueb6dguam5gyflj3kaq4emfq`
- **Region**: `us-ashburn-1` (iad)
- **OS**: Oracle Linux 9
- **Username**: `opc`

### **SSH Key Location**
```bash
~/.ssh/oracle_fennel_key
```

## 🛠️ **Complete Login Process**

### **Step-by-Step Commands**

1. **Check if instance is running**:
   ```bash
   oci compute instance get --instance-id ocid1.instance.oc1.iad.anuwcljtwd4qh7ickcucoeximyxua4ebuv33ueb6dguam5gyflj3kaq4emfq --query 'data.{state:"lifecycle-state",name:"display-name"}' --output table
   ```

2. **Get current public IP**:
   ```bash
   oci compute instance list-vnics --instance-id ocid1.instance.oc1.iad.anuwcljtwd4qh7ickcucoeximyxua4ebuv33ueb6dguam5gyflj3kaq4emfq --query 'data[0].{"Public-IP":"public-ip","Private-IP":"private-ip","State":"lifecycle-state"}' --output table
   ```

3. **Connect using current IP**:
   ```bash
   ssh -i ~/.ssh/oracle_fennel_key opc@CURRENT_PUBLIC_IP
   ```

## 🚨 **Troubleshooting**

### **Connection Timeout**
- **Check instance state**: Instance might be stopped
- **Verify IP address**: IP may have changed after restart
- **Test connectivity**: `ping CURRENT_PUBLIC_IP`

### **Permission Denied**
- **Wrong username**: Use `opc` for Oracle Linux, `ubuntu` for Ubuntu
- **Key permissions**: Ensure SSH key has correct permissions:
  ```bash
  chmod 600 ~/.ssh/oracle_fennel_key
  ```
- **Wrong key**: Verify you're using the correct SSH key file

### **Common Issues and Solutions**

| Issue | Solution |
|-------|----------|
| Connection timeout | Check instance is running, verify IP address |
| Permission denied | Use correct username (`opc` for Oracle Linux) |
| Host key verification failed | Remove old host key: `ssh-keygen -R OLD_IP` |
| Key not found | Verify key path: `ls -la ~/.ssh/oracle_fennel_key` |

## 📊 **Quick Reference Commands**

### **Instance Management**
```bash
# Start instance
oci compute instance action --instance-id OCID --action START

# Stop instance  
oci compute instance action --instance-id OCID --action STOP

# Restart instance
oci compute instance action --instance-id OCID --action SOFTRESET
```

### **Network Information**
```bash
# Get all instance details
oci compute instance get --instance-id OCID

# Get network interfaces
oci compute instance list-vnics --instance-id OCID
```

## 🛡️ **Security Notes**

- **SSH Key**: Keep your SSH private key secure (`~/.ssh/oracle_fennel_key`)
- **Permissions**: SSH key should have 600 permissions
- **IP Changes**: Public IP may change when instance restarts
- **Firewall**: Ensure port 22 (SSH) is open in security lists

## 🔄 **After Connecting**

Once connected to your Oracle Cloud instance:

1. **Navigate to validator**:
   ```bash
   cd FennelValidator
   ```

2. **Check validator status**:
   ```bash
   ./validate.sh status
   ```

3. **Stop validator**:
   ```bash
   ./validate.sh stop
   ```

4. **Start validator**:
   ```bash
   ./validate.sh start
   ```

## 📞 **Need Help?**

If you encounter issues:
1. Check Oracle Cloud Console for instance status
2. Verify security list rules allow SSH (port 22)
3. Ensure your SSH key is correctly configured
4. Check Oracle CLI configuration: `oci setup config`

---

**Last Updated**: Based on successful connection to `slowblock-validator-ol9` instance 