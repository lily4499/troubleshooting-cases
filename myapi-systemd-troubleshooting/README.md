
# Linux Ops Scenario: **myapi** systemd Service Failing

**systemctl status + journalctl — From Scratch Problem + Fix**

## Context

I worked on a Linux Ops scenario where an internal API service called **myapi** stopped running on a server.

This kind of issue matters because when a systemd-managed service fails, users may lose access to the application, other dependent services may also fail, and the server can enter a restart loop if the root cause is not fixed correctly.

In this scenario, I investigated the failure using **systemctl** and **journalctl**, identified the root cause, fixed it, and validated that the service came back healthy and stable.

---

## Problem

The **myapi** service went down on the Linux server.

Because of that:

* users could no longer reach the API
* dependent applications could not communicate with the service
* the service showed as **failed**
* systemd was attempting to restart it repeatedly
* the application port was no longer listening

This is a common Linux operations issue: a service is down, but the important part is not only restarting it — it is finding the **real reason** it failed and fixing that root cause cleanly.

---

## Solution

I solved the issue by following a standard Linux operations troubleshooting flow:

1. I confirmed the service failure with `systemctl status`
2. I checked service logs with `journalctl`
3. I identified the root cause: the service depended on an environment file that was missing
4. I created the missing configuration file and applied correct permissions
5. I restarted the service
6. I validated that the service was running, the port was listening, and the API responded successfully
7. I confirmed the service was stable and no longer stuck in a restart loop

This restored the API and proved the issue was resolved at the root, not just temporarily masked.

---

## Architecture

![Architecture Diagram](screenshots/architecture.png)

This setup is simple:

* **systemd** manages the `myapi` service
* the service runs a Python-based API application
* the application depends on an external environment file at `/etc/myapi/myapi.env`
* if that file is missing, systemd cannot start the service correctly
* logs are reviewed through **journalctl**
* service state is checked through **systemctl**
* final validation is done through port checks and an HTTP health request

---

## Workflow with Goals + Screenshots

### 1. Confirm the service is failing

**Goal:** verify that the issue is real and see the first visible failure details.

I started by checking the service state in systemd. This showed that `myapi.service` was in a failed state, which confirmed the outage and gave the first indication that the service was not starting successfully.

**Screenshot:**
![myapi failed status](screenshots/01-myapi-failed-status.png)

**What it should show:**

* `myapi.service` in **failed** state
* restart attempts or failure result
* service not active

---

### 2. Read logs to identify the root cause

**Goal:** move from symptom to root cause using service logs.

After confirming the service failure, I checked the logs with journalctl. The logs showed that systemd could not load the required environment file. This explained why the service could not start.

**Screenshot:**
![myapi journalctl error](screenshots/02-myapi-journalctl-error.png)

**What it should show:**

* error related to missing `/etc/myapi/myapi.env`
* service exited with failure
* proof that the issue is configuration-related, not just a random crash

---

### 3. Verify the missing configuration file

**Goal:** confirm the root cause before applying the fix.

Before fixing the issue, I verified that the environment file was actually missing. This step is important because it confirms the diagnosis before making changes.

**Screenshot:**
![missing env file](screenshots/03-missing-env-file.png)

**What it should show:**

* missing file check or failed lookup
* proof that the expected environment file was not present

---

### 4. Create the environment file needed by the service

**Goal:** restore the configuration dependency required for startup.

I created the missing environment file with the values the service needed, such as the application port and API message.

**Screenshot:**
![env file created](screenshots/04-env-file-created.png)

**What it should show:**

* the env file now exists
* correct variables are defined inside it

---

### 5. Restart the service and confirm it is healthy

**Goal:** bring the service back online and verify systemd shows it as running.

Once the missing file was created and permissions were corrected, I restarted the service and checked its state again. This time, systemd showed the service as active and running.

**Screenshot:**
![myapi running status](screenshots/05-myapi-running-status.png)

**What it should show:**

* `myapi.service` is **active (running)**
* no immediate failure after restart

---

### 6. Confirm the application port is listening

**Goal:** verify the process is actually serving on the expected port.

A service can appear active, but I still needed to confirm the application was listening on the correct network port. I checked the listening sockets and confirmed port `3000` was open.

**Screenshot:**
![port listening](screenshots/06-port-listening.png)

**What it should show:**

* port `3000` listening
* process bound successfully

---

### 7. Validate the API response

**Goal:** confirm the service works from an application point of view, not only a process point of view.

After confirming the service was running and listening, I tested the API health endpoint. The request returned a successful response, which confirmed the application was working properly.

**Screenshot:**
![curl health success](screenshots/07-curl-health-success.png)

**What it should show:**

* successful health check response
* expected service message returned

---

### 8. Confirm the service is stable

**Goal:** make sure the fix is durable and the service is no longer restarting repeatedly.

As a final validation step, I checked the service behavior after the fix to confirm there was no restart loop and that the service stayed healthy.

**Screenshot:**
![restarts stability](screenshots/08-restarts-stability.png)

**What it should show:**

* low or stable restart count
* proof that the service remained up after the fix

---

## Business Impact

This issue directly affects service availability.

If this API is down:

* users cannot access the application feature that depends on it
* internal integrations may fail
* alerts may increase because health checks fail
* operations teams lose time if they restart the service without fixing the real cause

By identifying the missing environment file and restoring the service properly, I reduced downtime and restored application availability quickly.

This kind of work shows practical Linux operations skills:

* diagnosing service failures
* using logs to find root cause
* fixing configuration issues safely
* validating stability after recovery

---

## Troubleshooting

Here are the main checks I would use in this type of Linux service incident:

### Service shows failed

Check service state first to confirm whether systemd sees it as failed, inactive, or restarting.

### Service stuck in restart loop

Look at restart counters and recent logs to determine whether the service is repeatedly crashing.

### Missing configuration or environment file

Check whether the service depends on an env file, config file, secret, or path that no longer exists.

### Permission issue

Even if the file exists, the service user may not have permission to read it.

### Port not listening

If the service says running but the port is not open, the process may have started incorrectly or exited immediately after launch.

### App works manually but not under systemd

This usually points to environment differences, wrong working directory, incorrect user, or missing dependency inside the unit configuration.

---

## Useful CLI

### Main investigation commands

```bash
sudo systemctl status myapi --no-pager -l
sudo journalctl -u myapi -n 200 --no-pager
sudo systemctl cat myapi
sudo systemctl show myapi -p EnvironmentFile
```

### Validation commands

```bash
sudo ss -lntp | grep ':3000' || true
curl -s http://localhost:3000/health
sudo systemctl show myapi -p NRestarts -p ActiveEnterTimestamp
```

### Troubleshooting CLI

```bash
sudo journalctl -u myapi -f
sudo ls -l /etc/myapi/myapi.env
sudo cat /etc/myapi/myapi.env
sudo -u myapi /usr/bin/python3 /opt/myapi/app.py
sudo systemctl daemon-reload
sudo systemctl restart myapi
```

These commands help quickly answer:

* Is the service failed?
* Why did it fail?
* Is the config file present?
* Can the app run correctly?
* Is the port listening?
* Is the service stable after restart?

---

## Cleanup

If I want to remove this demo setup after testing, I clean up the service, application files, and environment file.

```bash
sudo systemctl stop myapi
sudo systemctl disable myapi
sudo rm -f /etc/systemd/system/myapi.service
sudo systemctl daemon-reload
sudo rm -rf /opt/myapi
sudo rm -rf /etc/myapi
sudo userdel myapi || true
```

This removes the demo service and returns the server to a clean state.

---
