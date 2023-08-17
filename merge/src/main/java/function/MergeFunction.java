package function;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.google.cloud.functions.HttpFunction;
import com.google.cloud.functions.HttpRequest;
import com.google.cloud.functions.HttpResponse;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import shared.Credentials;
import storage.Storage;
import storage.StorageImpl;

import javax.sound.sampled.AudioFileFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.SequenceInputStream;

public class MergeFunction implements HttpFunction, RequestHandler<MergeInput, MergeOutput> {

  private static final Gson gson = new Gson();

  @Override
  public MergeOutput handleRequest(MergeInput input, Context context) {
    try {
      return doWork(input);
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public void service(HttpRequest request, HttpResponse response) throws Exception {
    JsonObject body = gson.fromJson(request.getReader(), JsonObject.class);
    MergeInput input = gson.fromJson(body.toString(), MergeInput.class);
    MergeOutput output = doWork(input);
    response.getWriter().write(gson.toJson(output));
  }

  public MergeOutput doWork(MergeInput input) throws Exception {
    Credentials credentials = Credentials.loadDefaultCredentials();
    Storage storage = new StorageImpl(credentials);
    AudioInputStream audioInputStream = null;
    for (String inputFile : input.getInputFiles()) {
      byte[] inputAudio = storage.read(inputFile);
      AudioInputStream chunk =
          AudioSystem.getAudioInputStream(new ByteArrayInputStream(inputAudio));
      if (audioInputStream == null) {
        audioInputStream = chunk;
      } else {
        audioInputStream =
            new AudioInputStream(
                new SequenceInputStream(audioInputStream, chunk),
                audioInputStream.getFormat(),
                audioInputStream.getFrameLength() + chunk.getFrameLength());
      }
    }
    // write result to output file
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    AudioSystem.write(audioInputStream, AudioFileFormat.Type.WAVE, outputStream);
    String outputFile = input.getOutputBucket() + "result.wav";
    storage.write(outputStream.toByteArray(), outputFile);
    // return response
    return MergeOutput.builder().outputFile(outputFile).build();
  }
}
