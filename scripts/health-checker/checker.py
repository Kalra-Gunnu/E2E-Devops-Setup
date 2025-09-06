#!/usr/bin/env python3
import logging
from kubernetes import client, config
logging.basicConfig(level=logging.INFO)
try:
    config.load_incluster_config()
except:
    config.load_kube_config()
v1 = client.CoreV1Api()
def restart_crashloop_pods():
    pods = v1.list_pod_for_all_namespaces(watch=False)
    for p in pods.items:
        statuses = p.status.container_statuses or []
        for st in statuses:
            if st.state.waiting and st.state.waiting.reason == "CrashLoopBackOff":
                logging.info(f"Deleting pod {p.metadata.name} in ns {p.metadata.namespace}")
                try:
                    v1.delete_namespaced_pod(p.metadata.name, p.metadata.namespace)
                except Exception as e:
                    logging.error(e)
if __name__ == '__main__':
    restart_crashloop_pods()
