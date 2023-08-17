package function;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.google.cloud.functions.HttpFunction;
import com.google.cloud.functions.HttpRequest;
import com.google.cloud.functions.HttpResponse;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.apache.commons.io.FilenameUtils;
import recognition.SpeechRecognitionRequest;
import recognition.SpeechRecognitionResponse;
import recognition.SpeechRecognizer;
import shared.Configuration;
import shared.Credentials;
import shared.Provider;
import storage.Storage;
import storage.StorageImpl;

import java.io.IOException;

public class TranscribeFunction
    implements HttpFunction, RequestHandler<TranscribeInput, TranscribeOutput> {

  private static final Gson gson = new Gson();

  @Override
  public TranscribeOutput handleRequest(TranscribeInput input, Context context) {
    try {
      return doWork(input);
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public void service(HttpRequest request, HttpResponse response) throws Exception {
    JsonObject body = gson.fromJson(request.getReader(), JsonObject.class);
    TranscribeInput input = gson.fromJson(body.toString(), TranscribeInput.class);
    TranscribeOutput output = doWork(input);
    response.getWriter().write(gson.toJson(output));
  }

  public TranscribeOutput doWork(TranscribeInput input) throws Exception {
    // construct output file url
    String baseName = FilenameUtils.getBaseName(input.getInputFile());
    String outputFile = input.getOutputBucket() + "transcribe/" + baseName + "." + "txt";
    // invoke speech recognition
    SpeechRecognizer recognizer =
        new SpeechRecognizer(Configuration.builder().build(), Credentials.loadDefaultCredentials());
    SpeechRecognitionRequest request =
        SpeechRecognitionRequest.builder()
            .inputFile(input.getInputFile())
            .languageCode(input.getLanguage())
            .sampleRate(16000)
            .channelCount(1)
            .build();
    SpeechRecognitionResponse response =
        recognizer.recognizeSpeech(request, Provider.valueOf(input.getProvider()));
    // write result to output bucket
    Storage storage = new StorageImpl(Credentials.loadDefaultCredentials());
    storage.write(response.getFullTranscript().getBytes(), outputFile);
    // return response
    return TranscribeOutput.builder().outputFile(outputFile).build();
  }

  public static void main(String[] args) throws Exception {
    TranscribeInput input = TranscribeInput.builder()
            .inputFile("https://storage.cloud.google.com/tommi-test-bucket/recognition-15.wav")
            .outputBucket("https://storage.cloud.google.com/tommi-test-bucket/")
            .language("de-DE")
            .provider("GCP")
            .build();
    TranscribeFunction function = new TranscribeFunction();
    TranscribeOutput output = function.doWork(input);
    System.out.println(output);
  }
}
