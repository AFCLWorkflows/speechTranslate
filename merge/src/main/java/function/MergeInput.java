package function;

import lombok.*;

import java.util.List;

@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@ToString
public class MergeInput {
    private List<String> inputFiles;
    private String outputBucket;
}
