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

import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

public class CollectFunction implements HttpFunction, RequestHandler<CollectInput, CollectOutput> {

  private static final Gson gson = new Gson();

  @Override
  public CollectOutput handleRequest(CollectInput input, Context context) {
    try {
      return doWork(input);
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public void service(HttpRequest request, HttpResponse response) throws Exception {
    JsonObject body = gson.fromJson(request.getReader(), JsonObject.class);
    CollectInput input = gson.fromJson(body.toString(), CollectInput.class);
    CollectOutput output = doWork(input);
    response.getWriter().write(gson.toJson(output));
  }

  public CollectOutput doWork(CollectInput input) throws IOException {
    Credentials credentials = Credentials.loadDefaultCredentials();
    Storage storage = new StorageImpl(credentials);
    List<String> fileNames = storage.listFiles(input.getInputBucket());
    List<String> fileUrls =
        fileNames.stream()
            .map(filename -> input.getInputBucket() + filename)
            .collect(Collectors.toList());
    return CollectOutput.builder().files(fileUrls).filesCount(fileUrls.size()).build();
  }

  public static void main(String[] args) throws IOException {
    CollectFunction function = new CollectFunction();
    CollectOutput output =
        function.doWork(
            CollectInput.builder()
                .inputBucket("https://tommi-test-bucket.s3.amazonaws.com/")
                .build());
    System.out.println(output);
  }
}
