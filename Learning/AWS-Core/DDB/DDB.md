# DynamoDB Primary Key Basics

A primary key is used to uniquely identify each item in DynamoDB.

## Types of Primary Keys

DynamoDB supports two types of primary keys:

1. **Partition key**
2. **Partition key + sort key**

## Partition Key

The partition key is the input to DynamoDB's internal hash function. The output of that function determines which partition stores the item.

## Partition Key + Sort Key

When both a partition key and a sort key are used, this is called a **composite primary key**.

In this case, the partition key does not need to be unique across items. The sort key is used to order and distinguish items within the same partition, and it should be unique for that purpose.

## Alternate Names

- Partition key = **hash attribute**
- Sort key = **range attribute**

## Allowed Data Types for Partition Key

A partition key can only be of the following types:

- String
- Binary
- Number

## Secondary Indexes

You can create one or more secondary indexes on a table. This allows you to query the data using an alternate key instead of the primary key, giving you more flexibility.

### Global Secondary Index (GSI)

A global secondary index has a partition key and sort key that are both different from the table's primary key. The primary key in a GSI does not need to be unique.

### Local Secondary Index (LSI)

A local secondary index uses the same partition key as the table but a different sort key.

## On-Demand vs Provisioned Throughput

### On-Demand Capacity

- Offers serverless-style scaling without the need to plan capacity in advance.
- Best suited for unpredictable or sudden traffic spikes.
- You pay per request.

### Provisioned Throughput

- Suitable for steady and predictable traffic where cost optimization is important.
- You must define read and write capacity units (RCUs and WCUs).
- You are charged hourly for the configured capacity, even if you do not fully use it.

## DynamoDB Streams

DynamoDB Streams capture data modifications made to a table. Each change is represented as a stream record.

When streams are enabled on a DynamoDB table, DynamoDB writes a stream record for the following events:

1. **New item added** — captures the entire item, including all attributes.
2. **Item deleted** — captures the before-and-after image of the modified attributes.
3. **Item updated** — captures the item's state before and after the update.

Each stream record contains the table name, event timestamp, and metadata. The retention period, or lifespan, of a stream record is 24 hours.


