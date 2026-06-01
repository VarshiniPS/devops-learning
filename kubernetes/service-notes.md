# Kubernetes Service Notes

## Expose Deployment

kubectl expose deployment nginx-deployment --type=NodePort --port=80

Creates a Service to expose the nginx deployment externally.

---

## View Services

kubectl get svc

Displays all Kubernetes Services.

---

## NodePort Service

NodePort exposes the application using a port on the machine.

Example:
80:31245/TCP

* 80 = container application port
* 31245 = external access port

Application can be accessed using:
http://localhost:<NodePort>

---

## Observations

* Service provides stable networking for Pods.
* Users should not directly access Pods because Pods are temporary.
* Service routes traffic to healthy Pods.
* NodePort exposes applications externally using machine ports.
* Service acts like a reception counter between users and Pods.
