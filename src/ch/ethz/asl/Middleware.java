package ch.ethz.asl;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.LinkedBlockingQueue;

/**
 * Starts the net-thread responsible for client connections. Starts the worker-threads responsible for server
 * connections.
 */
public class Middleware {


    // access to threads needed for shutdown-hook
    private NetThread   netThread;
    private ArrayList<WorkerThread> workerThreadPool;

    // contains all requests that will be enqueued by the net-thread
    private LinkedBlockingQueue<Request> requestQueue;


    public Middleware(String myIp, int myPort, List<String> mcAddresses, int numThreadsPTP, boolean readSharded) {

        requestQueue = new LinkedBlockingQueue<>();
        workerThreadPool = new ArrayList<>();

        startNetThread(myIp, myPort);
        startWorkerThreads(mcAddresses, numThreadsPTP, readSharded);
    }

    private void startNetThread(String myIp, int myPort) {
        netThread = new NetThread(myIp, myPort, this.requestQueue);
        netThread.start();
    }

    private void startWorkerThreads(List<String> mcAddresses, int numThreadsPTP, boolean readSharded){
        for(int i = 0; i < numThreadsPTP; i++) {
            WorkerThread worker = new WorkerThread(mcAddresses, readSharded, requestQueue);
            workerThreadPool.add(worker);
            worker.start();
        }

    }


}
