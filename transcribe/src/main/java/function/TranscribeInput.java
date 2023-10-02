package function;

import lombok.*;

import java.util.List;

@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@ToString
public class TranscribeInput {
    private String inputFile;
    private String outputBucket;
    private String language;
    private String provider;
    private String region;
}
