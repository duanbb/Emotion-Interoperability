function FilteredAnnotations = Filter(OriginalAnnotations, N_workers)
    original_sentence_workers = GetSentenceWorkers(OriginalAnnotations);
    n_sentences = length(original_sentence_workers);
    filtered_sentence_workers = cell(n_sentences, 1);
    labels = fieldnames(OriginalAnnotations.(original_sentence_workers{1}{1}));
    for i = 1:n_sentences %ÿ��sentence������worker
        all_workers = original_sentence_workers{i};
        worker_Nlabels_map = containers.Map();
        for j = 1:length(all_workers) %��sentence��ÿ��worker
            worker = all_workers{j};
            annotation = OriginalAnnotations.(worker)(i);
            n_trueLabels = 0;
            for k = 1:length(labels)
                if annotation.(labels{k}) 
                    n_trueLabels = n_trueLabels + 1;
                end
            end
            clear k
            worker_Nlabels_map(worker) = n_trueLabels;
            clear n_trueLabels;
        end
        clear j worker annotation
        sorted_worker_Nlabels_cell = Map2SortedCell(worker_Nlabels_map);
        filtered_sentence_workers{i} = cell(N_workers, 1);
        for j = 1:N_workers
            filtered_sentence_workers{i}{j} = sorted_worker_Nlabels_cell{j,1};
        end
        clear j
    end
    clear i sentence
    
    empty_annotation = EmptyAnnotation(labels);
    %���ɹ��˺�����ݡ�����ÿ�䣬����ǰ30�ڵ��˵ı�ע����Ϊ�գ�����û��ע�˾䣩
    FilteredAnnotations = OriginalAnnotations; %struct�����
    for i = 1:n_sentences %ÿһ��
        filtered_workers = filtered_sentence_workers{i}; %��ǰ���ǰ30worker
        for j = 1:length(all_workers)
            cur_worker = all_workers{j};
            if ~any(strcmp(filtered_workers, cur_worker))
                FilteredAnnotations.(cur_worker)(i) = empty_annotation;
            end
        end
        clear j cur_worker
    end
    clear i
end