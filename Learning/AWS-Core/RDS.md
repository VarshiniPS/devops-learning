# Amazon RDS

Amazon RDS is an easy-to-manage relational database service. It is simple to set up, operate, and scale on demand. AWS handles the administrative tasks so you can focus more on applications and users.

## 1. Multi-AZ vs Read Replicas

Multi-AZ RDS deployments provide enhanced durability and availability for your RDS database instances. They are mainly used for high availability.

### RDS Multi-AZ with one standby
- Automatic failover occurs if the primary instance fails, and RDS switches to the standby instance.
- Failover usually takes around 60 seconds, with no data loss.
- I/O activity on the primary database is suspended during backup, and the backup is taken from the standby instance.
- Synchronous replication happens from the primary to the standby instance, so the standby is always up to date.
- It provides high availability by keeping a standby in a second Availability Zone.
- It does not serve read traffic.

### RDS Multi-AZ with two readable standbys
- Automatic failover occurs in under 35 seconds with no data loss and minimal manual intervention.
- It uses separate endpoints for read and write traffic, which improves performance.
- Minor version upgrades are typically completed in under 1 second.
- It provides about 2x improved write latency compared to the earlier setup.
- It can serve read traffic.

## 2. Read Replicas
- Read replicas help reduce the load on the primary instance, especially for heavy read traffic.
- They are usually created from a snapshot of the primary instance in most RDS engines.
- Asynchronous replication occurs between the read replica and the primary instance.
- A read replica can be promoted to become a standalone database.
- They are useful for disaster recovery and scaling read workloads.

## Key Difference
- Multi-AZ is mainly for high availability and failover protection.
- Read Replicas are mainly for scaling read traffic and reducing load on the primary database.