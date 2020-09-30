package org.apache.cordova.media;

import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.Arrays;

import android.os.AsyncTask;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;

public class SocketServer implements Runnable {

    private static final String TAG = "SocketServer";
    private static final int SERVER_PORT = 8888;

    private Thread thread;
    private boolean isRunning;
    private ServerSocket socket;
    private int port;
    private HttpStreamingTask task;

    public SocketServer() {
        try {
            socket = new ServerSocket(SERVER_PORT, 0, InetAddress.getByAddress(new byte[] { 127, 0, 0, 1 }));
            socket.setSoTimeout(5000);
            port = socket.getLocalPort();
        } catch (UnknownHostException e) {
        } catch (IOException e) {
            Log.e(TAG, "IOException initializing server", e);
        }
    }

    public void start() {
        thread = new Thread(this);
        thread.start();
    }

    public void stop() {
        isRunning = false;
        thread.interrupt();
        try {
            thread.join(5000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void run() {
        Looper.prepare();
        isRunning = true;
        while (isRunning) {
            try {
                Socket client = socket.accept();
                if (client == null) {
                    continue;
                }
                if (task != null) {
                    task.client.close();
                    task.cancel(true);
                }
                task = new HttpStreamingTask(client);
                if (task.processRequest()) {
                    task.execute();
                }
            } catch (SocketTimeoutException e) {
            } catch (IOException e) {
            }
        }
    }

    private class HttpStreamingTask extends AsyncTask <String, Void, Integer> {

        String localPath;
        Socket client;
        int cbSkip;
        boolean isBlocking = false;
        long fileSize;

        public HttpStreamingTask(Socket client) {
            this.client = client;
        }

        private String readHeaders(InputStream inputStream) throws IOException {
            byte[] buffer = new byte[4096];
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream(4096);
            outputStream.write(inputStream.read());

            int available = inputStream.available();
            while (available > 0) {
                int cbToRead = Math.min(buffer.length, available);
                int cbRead = inputStream.read(buffer, 0, cbToRead);
                if (cbRead <= 0) {
                    throw new IOException("Unexpected EOS");
                }
                outputStream.write(buffer, 0, cbRead);
                available -= cbRead;
            }
            return new String(outputStream.toByteArray());
        }

        public boolean processRequest() {
            String headers = "";
            try {
                headers = readHeaders(client.getInputStream());
            } catch (IOException e) {
                Log.e(TAG, "Error request header:", e);
                return false;
            }

            String[] headerLines = headers.split("\n");
            String urlLine = headerLines[0];
            if (!urlLine.startsWith("GET ")) {
                return false;
            }
            urlLine = urlLine.substring(4);
            int charPos = urlLine.indexOf(' ');
            if (charPos != -1) {
                urlLine = urlLine.substring(1, charPos);
            }
            String[] temp = urlLine.split("/");
            fileSize = Long.parseLong(temp[temp.length - 1]);

            String[] tempLocalPath = Arrays.copyOf(temp, temp.length - 1, String[].class);
            localPath = TextUtils.join("/", tempLocalPath);

            for (int i = 0; i < headerLines.length; i++) {
                String headerLine = headerLines[i];
                if (headerLine.startsWith("Range: bytes=")) {
                    headerLine = headerLine.substring(13);
                    charPos = headerLine.indexOf('-');
                    if (charPos > 0) {
                        headerLine = headerLine.substring(0, charPos);
                    }
                    cbSkip = Integer.parseInt(headerLine);
                }
            }
            return true;
        }

        @Override
        protected Integer doInBackground(String...params) {
            String headers = "HTTP/1.0 206 Partial Content\r\n";
            headers += "Content-Type: " + "audio/mpeg" + "\r\n";
            headers += "Content-Length: " + fileSize + "\r\n";
            headers += "Connection: close\r\n";
            headers += "\r\n";

            int fc = 0;
            long cbToSend = fileSize - cbSkip;
            OutputStream output = null;
            byte[] buff = new byte[256 * 1024];
            
            try {
                output = new BufferedOutputStream(client.getOutputStream(), 256 * 1024);
                output.write(headers.getBytes());

                while (isRunning && cbToSend > 0 && !client.isClosed()) {
                    File file = new File(localPath);
                    fc++;
                    int cbSentThisBatch = 0;
                    
                    if (file.exists()) {
                        FileInputStream input = new FileInputStream(file);
                        input.skip(cbSkip);
                        int cbToSendThisBatch = input.available();
                        while (cbToSendThisBatch > 0) {
                            int cbToRead = Math.min(cbToSendThisBatch, buff.length);
                            int cbRead = input.read(buff, 0, cbToRead);
                            if (cbRead == -1) {
                                break;
                            }
                            cbToSendThisBatch -= cbRead;
                            cbToSend -= cbRead;
                            output.write(buff, 0, cbRead);
                            output.flush();
                            cbSkip += cbRead;
                            cbSentThisBatch += cbRead;
                        }
                        input.close();
                    }

                    if (cbSentThisBatch == 0) {
                        Thread.sleep(1000);
                    }
                }

            } catch (SocketException socketException) {
            } catch (Exception e) {
                Log.e(TAG, e.getClass().getName() + " : " + e.getLocalizedMessage());
                e.printStackTrace();
            }

            try {
                if (output != null) {
                    output.close();
                }
                client.close();
            } catch (IOException e) {
                Log.e(TAG, e.getClass().getName() + " : " + e.getLocalizedMessage());
                e.printStackTrace();
            }

            return 1;
        }

    }
}