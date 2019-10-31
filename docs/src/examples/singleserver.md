### Single server

This example is from Choi, Kang: Modeling and Simulation of Discrete-Event Systems, p. 18. It describes a single server system. The event graph given is:

![single server](../../images/sserver.svg)

1. Initially there are no jobs in the queue Q and the machine M is idle.
2. Jobs arrive with an inter-arrival-time t<sub>a</sub> and are added to Q.
3. If M is idle, it loads a job, changes to busy and executes the job with service time t<sub>s</sub>.
4. After that it changes to idle and, if Q is not empty, it loads the next job.
