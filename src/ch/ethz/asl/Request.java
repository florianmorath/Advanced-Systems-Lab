package ch.ethz.asl;

import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;

/**
 * Represents a requests from a client.
 */
public class Request {

    // contains data of request
    public ByteBuffer buffer;

    // contains information about channel over which request was sent
    public SelectionKey key;

    public Request(ByteBuffer buffer, SelectionKey key){
        this.buffer = buffer;
        this.key = key;
    }

}