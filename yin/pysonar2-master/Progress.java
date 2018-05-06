package org.python.indexer;

public class Progress {

    long startTime;
    long total;
    long dotInterval;
    long reportInterval;

    long count;
    long mark;


    public Progress(long dotInterval, long width, long total) {
        this.startTime = System.currentTimeMillis();
        this.dotInterval = dotInterval;
        this.reportInterval = width * dotInterval;
        this.total = total;         // for calculating ETA

        this.count = 0;
        this.mark = reportInterval;
    }


    public Progress(long dotInterval, long width) {
        this.startTime = System.currentTimeMillis();
        this.dotInterval = dotInterval;
        this.reportInterval = width * dotInterval;
        this.total = -1;

        this.count = 0;
        this.mark = reportInterval;
    }


    public void tick(int n) {
        long oldCount = count;
        count += n;

        if (count % dotInterval == 0) {
            System.out.print(".");
        }

        // if the count goes cross the mark, report interval speed etc.
        if (oldCount < mark && count >= mark) {
            mark += reportInterval;
            intervalReport();
        }
    }


    public void tick() {
        tick(1);
    }


    public void end() {
    	intervalReport();
    	System.out.println();
    }


    public void intervalReport() {
        if (count % reportInterval == 0) {
            long endTime = System.currentTimeMillis();
            long totalTime = endTime - startTime;
            long seconds = totalTime / 1000;
            if (seconds == 0) { seconds = 1; }
            long rate = count / seconds;

            Util.msg("\n" + count + " items processed" +
                    ", time: " + Util.timeString(totalTime) +
                    ", rate: " + count / seconds);

            if (total > 0) {
                long rest = total - count;
                long eta = rest / rate;
                Util.msg("ETA: " + Util.timeString(eta * 1000));
            }
        }
    }
}
