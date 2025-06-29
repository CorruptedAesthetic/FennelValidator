# Staging Validator Learning Exercises

**🧪 Hands-on exercises to master Fennel validator operations in a safe environment**

## 🎯 **Purpose**

These exercises help you practice all aspects of validator operations without financial risk. Complete these in order to build confidence and expertise.

## 📋 **Exercise Checklist**

### **Phase 1: Basic Operations (Week 1)**

#### **Exercise 1.1: Initial Setup**
- [ ] **Goal**: Successfully deploy your first staging validator
- [ ] **Time**: 30 minutes
- [ ] **Steps**:
  ```bash
  # Complete installation
  ./install.sh
  
  # Run setup and document every choice made
  ./setup-validator.sh
  
  # Start validator
  ./validate.sh start
  
  # Verify it's working
  ./validate.sh status
  ```
- [ ] **Success Criteria**: Validator shows as "running" and connected to network

#### **Exercise 1.2: Monitoring Mastery**
- [ ] **Goal**: Understand your validator's health and performance
- [ ] **Time**: 20 minutes
- [ ] **Steps**:
  ```bash
  # Run comprehensive health check
  ./scripts/health-check.sh
  
  # Watch real-time logs
  ./validate.sh logs
  
  # Check Prometheus metrics
  curl http://localhost:9615/metrics | grep substrate_block_height
  curl http://localhost:9615/metrics | grep substrate_network_peers
  ```
- [ ] **Success Criteria**: Can interpret all health metrics and understand normal operation

#### **Exercise 1.3: Basic Management**
- [ ] **Goal**: Practice essential validator control commands
- [ ] **Time**: 15 minutes
- [ ] **Steps**:
  ```bash
  # Practice stop/start cycle
  ./validate.sh stop
  sleep 10
  ./validate.sh status  # Should show "not running"
  ./validate.sh start
  sleep 30
  ./validate.sh status  # Should show "running"
  
  # Practice restart
  ./validate.sh restart
  
  # Verify validator rejoined network
  ./scripts/health-check.sh
  ```
- [ ] **Success Criteria**: Validator can be controlled reliably

### **Phase 2: Troubleshooting (Week 2)**

#### **Exercise 2.1: Network Issues Simulation**
- [ ] **Goal**: Practice handling network connectivity problems
- [ ] **Time**: 30 minutes
- [ ] **Steps**:
  ```bash
  # Simulate network isolation
  sudo iptables -A OUTPUT -p tcp --dport 30333 -j DROP
  
  # Wait 2 minutes and check status
  ./scripts/health-check.sh
  # Should show peer connectivity issues
  
  # Restore network
  sudo iptables -D OUTPUT -p tcp --dport 30333 -j DROP
  
  # Monitor recovery
  watch -n 10 './scripts/health-check.sh'
  ```
- [ ] **Success Criteria**: Recognize network issues and restore connectivity

#### **Exercise 2.2: Disk Space Management**
- [ ] **Goal**: Handle low disk space scenarios
- [ ] **Time**: 20 minutes
- [ ] **Steps**:
  ```bash
  # Check current disk usage
  df -h data/
  
  # Create artificial disk pressure (if safe)
  # Find old log files
  find data/ -name "*.log" -mtime +1 -ls
  
  # Practice log cleanup
  find data/ -name "*.log" -mtime +7 -delete
  
  # Verify space recovered
  df -h data/
  ```
- [ ] **Success Criteria**: Can monitor and manage validator disk usage

#### **Exercise 2.3: Configuration Recovery**
- [ ] **Goal**: Practice recovering from configuration issues
- [ ] **Time**: 25 minutes
- [ ] **Steps**:
  ```bash
  # Backup current config
  cp config/validator.conf config/validator.conf.backup
  
  # Simulate configuration corruption
  echo "CORRUPTED=true" >> config/validator.conf
  
  # Try to start (should fail)
  ./validate.sh stop
  ./validate.sh start
  
  # Practice recovery
  cp config/validator.conf.backup config/validator.conf
  ./validate.sh start
  
  # Verify recovery
  ./validate.sh status
  ```
- [ ] **Success Criteria**: Can diagnose and recover from config issues

### **Phase 3: Advanced Operations (Week 3)**

#### **Exercise 3.1: Software Updates**
- [ ] **Goal**: Practice safe validator updates
- [ ] **Time**: 30 minutes
- [ ] **Steps**:
  ```bash
  # Check current version
  bin/fennel-node* --version
  
  # Run update process
  ./scripts/update-validator.sh
  
  # Verify update completed
  bin/fennel-node* --version
  
  # Check validator still working
  ./validate.sh status
  ./scripts/health-check.sh
  ```
- [ ] **Success Criteria**: Successfully update validator software without downtime

#### **Exercise 3.2: Performance Monitoring**
- [ ] **Goal**: Understand validator performance characteristics
- [ ] **Time**: 45 minutes
- [ ] **Steps**:
  ```bash
  # Monitor system resources
  top -p $(pgrep fennel-node)
  
  # Check memory usage over time
  free -h
  ps aux | grep fennel-node | awk '{print $6}'
  
  # Monitor block production participation
  curl -s -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "chain_getHeader", "params":[]}' \
    http://localhost:9944 | jq '.result.number'
  
  # Create performance baseline
  echo "=== Performance Baseline ===" > performance.log
  echo "Date: $(date)" >> performance.log
  echo "Memory: $(ps aux | grep fennel-node | awk '{print $6}')" >> performance.log
  echo "Block: $(curl -s -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "chain_getHeader", "params":[]}' \
    http://localhost:9944 | jq -r '.result.number')" >> performance.log
  ```
- [ ] **Success Criteria**: Establish performance baselines and monitoring routine

#### **Exercise 3.3: Emergency Procedures**
- [ ] **Goal**: Practice handling validator emergencies
- [ ] **Time**: 20 minutes
- [ ] **Steps**:
  ```bash
  # Practice emergency shutdown
  ./validate.sh stop
  pkill -f fennel-node  # Force kill if needed
  
  # Practice emergency data backup
  tar -czf emergency-backup-$(date +%Y%m%d).tar.gz data/ config/
  
  # Practice rapid restart
  ./validate.sh start
  
  # Verify rapid recovery
  ./scripts/health-check.sh
  ```
- [ ] **Success Criteria**: Can handle emergency scenarios quickly and safely

### **Phase 4: Mastery Validation (Week 4)**

#### **Exercise 4.1: Extended Uptime Challenge**
- [ ] **Goal**: Demonstrate stable long-term operation
- [ ] **Time**: 7 days
- [ ] **Steps**:
  ```bash
  # Start 7-day uptime challenge
  echo "Starting 7-day uptime challenge: $(date)" > uptime-challenge.log
  
  # Daily health checks
  for i in {1..7}; do
    echo "Day $i: $(date)" >> uptime-challenge.log
    ./scripts/health-check.sh >> uptime-challenge.log
    sleep 86400  # 24 hours
  done
  ```
- [ ] **Success Criteria**: Validator runs continuously for 7 days with >99% uptime

#### **Exercise 4.2: Complete Operational Playbook**
- [ ] **Goal**: Document all learned procedures
- [ ] **Time**: 2 hours
- [ ] **Create Documentation**:
  ```markdown
  # My Validator Playbook
  
  ## Daily Checks
  - [ ] Run health check
  - [ ] Check disk space
  - [ ] Review logs
  
  ## Weekly Tasks
  - [ ] Update software
  - [ ] Backup configuration
  - [ ] Review performance
  
  ## Emergency Procedures
  - [ ] Emergency shutdown steps
  - [ ] Recovery procedures
  - [ ] Contact information
  ```
- [ ] **Success Criteria**: Complete operational documentation created

#### **Exercise 4.3: Stress Testing**
- [ ] **Goal**: Test validator resilience under various conditions
- [ ] **Time**: 60 minutes
- [ ] **Steps**:
  ```bash
  # Test rapid restart cycles
  for i in {1..5}; do
    ./validate.sh stop
    sleep 30
    ./validate.sh start
    sleep 60
    ./scripts/health-check.sh
  done
  
  # Test configuration changes
  ./setup-validator.sh  # Reconfigure with different ports
  ./validate.sh restart
  ./scripts/health-check.sh
  
  # Test update process
  ./scripts/update-validator.sh
  ./scripts/health-check.sh
  ```
- [ ] **Success Criteria**: Validator handles all stress tests without issues

## 🎓 **Graduation Criteria**

**You've mastered staging validation when you can:**

- [ ] Deploy a validator from scratch in under 10 minutes
- [ ] Diagnose and resolve common issues independently
- [ ] Explain all health metrics and their meanings
- [ ] Handle emergency scenarios calmly and effectively
- [ ] Maintain >99% uptime for 7+ consecutive days
- [ ] Update validator software safely
- [ ] Monitor and optimize validator performance
- [ ] Document all operational procedures

## 🚀 **Next Steps After Mastery**

Once you've completed all exercises and demonstrated mastery:

1. **Celebrate!** 🎉 You're now a competent validator operator
2. **Consider Production**: Explore [FennelValidatorProduction](../FennelValidatorProduction/) *(under development)*
3. **Help Others**: Share your knowledge with other staging validators
4. **Stay Updated**: Keep practicing and learning new techniques

## 📊 **Exercise Log Template**

Track your progress:

```
Exercise Completion Log
=======================

Phase 1: Basic Operations
[ ] Exercise 1.1: Initial Setup - Date: ___ Notes: ___
[ ] Exercise 1.2: Monitoring Mastery - Date: ___ Notes: ___
[ ] Exercise 1.3: Basic Management - Date: ___ Notes: ___

Phase 2: Troubleshooting  
[ ] Exercise 2.1: Network Issues - Date: ___ Notes: ___
[ ] Exercise 2.2: Disk Management - Date: ___ Notes: ___
[ ] Exercise 2.3: Config Recovery - Date: ___ Notes: ___

Phase 3: Advanced Operations
[ ] Exercise 3.1: Software Updates - Date: ___ Notes: ___
[ ] Exercise 3.2: Performance Monitoring - Date: ___ Notes: ___
[ ] Exercise 3.3: Emergency Procedures - Date: ___ Notes: ___

Phase 4: Mastery Validation
[ ] Exercise 4.1: 7-Day Uptime - Date: ___ Notes: ___
[ ] Exercise 4.2: Documentation - Date: ___ Notes: ___
[ ] Exercise 4.3: Stress Testing - Date: ___ Notes: ___

Graduation: [ ] All exercises completed successfully
```

## 🆘 **Getting Help**

- **Stuck on an exercise?** Check [troubleshooting.md](troubleshooting.md)
- **Need clarification?** Create an issue in this repository
- **Want to share success?** Document your experience for other learners

Remember: **This is staging - experiment freely and learn from mistakes!** 