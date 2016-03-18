function Golds_struct = GetGolds(Annotations, N_sentences)
    golds_cell = cell(N_sentences, 1);
    gold_frequency = zeros(N_sentences,1); % for observing
    for i = 1:N_sentences
        string_freq_map = containers.Map();
        string_annotations = containers.Map();
        workers = fieldnames(Annotations);
        for j = 1:length(workers)
            annotation = Annotations.(workers{j})(i);
            if ~IsEmpty(annotation) %此句被此人标过
                string = Annotation2String(annotation);
                if(~string_freq_map.isKey(string))
                    string_freq_map(string) = 1;
                    string_annotations(string) = annotation;
                else
                    string_freq_map(string) = string_freq_map(string) + 1;
                end
            end
            clear j annotation string
        end
        clear workers
        [val, idx] = max(cell2mat(string_freq_map.values));%返回majority vote
        keys = string_freq_map.keys;
        golds_cell{i} = string_annotations(keys{idx});
        gold_frequency(i) = val;
        clear val idx keys
    end
    clear i
    Golds_struct = CellArray2StructArray(golds_cell);
end

function String = Annotation2String(Annotation)
    String = '';
    labels = fieldnames(Annotation);
    for i = 1:length(labels)
        if Annotation.(labels{i})
            String = strcat(String, labels{i}, ',');
        end
    end
end