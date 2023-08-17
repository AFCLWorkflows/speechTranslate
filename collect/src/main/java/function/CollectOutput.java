package function;

import lombok.*;

import java.util.List;

@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@ToString
public class CollectOutput {
    private List<String> files;
    private Integer filesCount;
}
