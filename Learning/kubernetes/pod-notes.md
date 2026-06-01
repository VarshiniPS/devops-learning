# Kubernetes Notes ☸️

## Why Kubernetes?

Docker can run containers, but managing containers manually at scale becomes difficult. Kubernetes automates deployment, scaling, recovery, and networking of containers.

## Docker vs Kubernetes

* Docker creates and runs containers.
* Kubernetes manages containers at scale.

## Pod

A Pod is the smallest deployable unit in Kubernetes and usually contains one container.

## Deployment

Deployment defines how many Pods should run and manages updates.

## ReplicaSet

ReplicaSet ensures the required number of Pods are always running.

## Service

Service provides stable networking and routes user traffic to healthy Pods.

## Kubernetes Flow

User → Service → Pods

Deployment → ReplicaSet → Pods
