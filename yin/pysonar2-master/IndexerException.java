package org.python.indexer;

/**
 * Signals that indexing is being aborted.
 * @see {Indexer#enableAggressiveAssertions}
 */
public class IndexerException extends RuntimeException {

    public IndexerException() {
    }

    public IndexerException(String msg) {
        super(msg);
    }

    public IndexerException(String msg, Throwable cause) {
        super(msg, cause);
    }

    public IndexerException(Throwable cause) {
        super(cause);
    }
}
