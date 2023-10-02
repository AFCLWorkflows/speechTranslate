package function;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.google.cloud.functions.HttpFunction;
import com.google.cloud.functions.HttpRequest;
import com.google.cloud.functions.HttpResponse;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.apache.commons.io.FilenameUtils;
import shared.Configuration;
import shared.Credentials;
import shared.Provider;
import storage.Storage;
import storage.StorageImpl;
import synthesis.*;

import javax.sound.sampled.AudioFileFormat;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

public class SynthesizeFunction
    implements HttpFunction, RequestHandler<SynthesizeInput, SynthesizeOutput> {

  private static final Gson gson = new Gson();

  @Override
  public SynthesizeOutput handleRequest(SynthesizeInput input, Context context) {
    try {
      return doWork(input);
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public void service(HttpRequest request, HttpResponse response) throws Exception {
    JsonObject body = gson.fromJson(request.getReader(), JsonObject.class);
    SynthesizeInput input = gson.fromJson(body.toString(), SynthesizeInput.class);
    SynthesizeOutput output = doWork(input);
    response.getWriter().write(gson.toJson(output));
  }

  public SynthesizeOutput doWork(SynthesizeInput input) throws Exception {
    // construct output file url
    String baseName = FilenameUtils.getBaseName(input.getInputFile());
    String outputFile = input.getOutputBucket() + "synthesis/" + baseName + "." + "wav";
    // invoke speech recognition
    SpeechSynthesizer synthesizer =
        new SpeechSynthesizer(
            Configuration.builder().build(), Credentials.loadDefaultCredentials());
    SpeechSynthesisRequest request =
        SpeechSynthesisRequest.builder()
            .inputFile(input.getInputFile())
            .gender(Gender.MALE)
            .textType(TextType.PLAIN_TEXT)
            .language(input.getLanguage())
            .build();
    SpeechSynthesisResponse response =
        synthesizer.synthesizeSpeech(request, Provider.valueOf(input.getProvider()), input.getRegion());
    // convert pcm to wav
    byte[] wav = pcmToWav(response.getAudio(), 16000, 16, 1);
    // write result to output bucket
    Storage storage = new StorageImpl(Credentials.loadDefaultCredentials());
    storage.write(wav, outputFile);
    // return response
    return SynthesizeOutput.builder().outputFile(outputFile).build();
  }

  private byte[] pcmToWav(byte[] data, int sampleRate, int sampleSizeInBits, int channelCount)
      throws IOException {
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    javax.sound.sampled.AudioFormat format =
        new AudioFormat(sampleRate, sampleSizeInBits, channelCount, true, false);
    AudioSystem.write(
        new AudioInputStream(new ByteArrayInputStream(data), format, data.length),
        AudioFileFormat.Type.WAVE,
        out);
    return out.toByteArray();
  }

  public static void main(String[] args) throws Exception {
    SynthesizeInput input =
        SynthesizeInput.builder()
            .inputFile(
                "https://storage.cloud.google.com/baassimless-test/sample-1.txt")
            .outputBucket("https://storage.cloud.google.com/baassimless-test/")
            .language("en-US")
            .provider("GCP")
                .region("us")
            .build();
    SynthesizeFunction function = new SynthesizeFunction();
    SynthesizeOutput output = function.doWork(input);
    System.out.println(output);
  }
}
