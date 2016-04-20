package org.apache.cordova.media;

import android.util.Log;

import com.coremedia.iso.boxes.Container;
import com.googlecode.mp4parser.FileDataSourceImpl;
import com.googlecode.mp4parser.authoring.Movie;
import com.googlecode.mp4parser.authoring.Track;
import com.googlecode.mp4parser.authoring.builder.DefaultMp4Builder;
import com.googlecode.mp4parser.authoring.container.mp4.MovieCreator;
import com.googlecode.mp4parser.authoring.tracks.AppendTrack;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.Channels;
import java.nio.channels.WritableByteChannel;
import java.util.List;


/**
 * Created by remoorejr on 12/16/15.
 */
public class mp4ParserWrapper {

    public static final String TAG = "Mp4ParserWrapper";

    public static final int FILE_BUFFER_SIZE = 1024;

    /**
     * Appends mp4 audios/videos: {@code anotherFileName} to {@code mainFileName}.
     */
    public static boolean append(String mainFileName, String anotherFileName) {
        boolean rvalue = false;
        try {
            final File targetFile = new File(mainFileName);
            final File anotherFile = new File(anotherFileName);
            if (targetFile.exists() && targetFile.length() > 0) {
                // the target file already exists, just append the new content
                String tmpFileName = mainFileName + ".tmp";
                append(mainFileName, anotherFileName, tmpFileName);
                copyFile(tmpFileName, mainFileName);
                rvalue = anotherFile.delete() && new File(tmpFileName).delete();
            } else {
                // create the target file
                final File parent = targetFile.getParentFile();
                if (!parent.exists() && !parent.mkdirs()) {
                    // impossible to create the directory folder
                    Log.e(TAG, "Impossible to create the directory");
                    throw new IllegalArgumentException("Impossible to create the directory");
                } else {
                    // the target direct
                    if (!targetFile.createNewFile()) {
                        Log.e(TAG, "Impossible to create the file");
                        throw new IllegalArgumentException("Impossible to create the file");
                    } else {
                        copyFile(anotherFileName, mainFileName);
                        rvalue = anotherFile.delete();
                    }
                }
            }
        } catch (IOException e) {
            Log.e(TAG, "Append two mp4 files exception", e);
        }
        return rvalue;
    }

    /**
     * Copy one file inside another one.
     * @param from
     * @param destination
     * @throws IOException
     */
    private static void copyFile(final String from, final String destination)
            throws IOException {
        FileInputStream in = null;
        FileOutputStream out = null;
        try {
            in = new FileInputStream(from);
            out = new FileOutputStream(destination);
            copy(in, out);
        } finally {
            if (in != null) {
                try {in.close();}  catch(IOException e) {};
            }
            if (out != null) {
                try {out.close();} catch(IOException e) {};
            }
        }
    }

    private static void copy(FileInputStream in, FileOutputStream out) throws IOException {
        byte[] buf = new byte[FILE_BUFFER_SIZE];
        int len;
        while ((len = in.read(buf)) > 0) {
            out.write(buf, 0, len);
        }
    }

    public static void append(
            final String firstFile,
            final String secondFile,
            final String newFile) throws IOException {
        final Movie movieA = MovieCreator.build(new FileDataSourceImpl(secondFile));
        final Movie movieB = MovieCreator.build(new FileDataSourceImpl(firstFile));

        final Movie finalMovie = new Movie();

        final List<Track> movieOneTracks = movieA.getTracks();
        final List<Track> movieTwoTracks = movieB.getTracks();

        for (int i = 0; i < movieOneTracks.size() || i < movieTwoTracks.size(); ++i) {
            finalMovie.addTrack(new AppendTrack(movieTwoTracks.get(i), movieOneTracks.get(i)));
        }

        final Container container = new DefaultMp4Builder().build(finalMovie);

        FileOutputStream fos = null;
        try {
            fos =  new FileOutputStream(new File(String.format(newFile)));
            final WritableByteChannel bb = Channels.newChannel(fos);
            container.writeContainer(bb);
        } finally {
            if (fos != null) {
                try {fos.close();} catch (Exception e) {};
            }
        }
    }

}
