function Worker_annotation = IntegrateData(Worker_annotation_cell, Start_array)
    for i = 1:length(Worker_annotation_cell) %取出每一个数据集
        workers = fieldnames(Worker_annotation_cell{i});
        for j = 1:length(workers) %取出每个worker的数据
            for k = 1:length(Worker_annotation_cell{i}.(workers{j})) %取出此worker的每个annotation
                Worker_annotation.(workers{j})(k + Start_array(i) - 1, 1) = Worker_annotation_cell{i}.(workers{j})(k);% 按列存储
            end
        end
        clear j
    end
    clear i
    
    %生成补全用的annotations
    labels = fieldnames(Worker_annotation.(workers{1})(1));
    empty_annotation = EmptyAnnotation(labels);
    
    n_sentences = k + Start_array(end) - 1; %最后一个数据集的数据个数 + 最后一个数据集的起始位置 - 1
    workers = fieldnames(Worker_annotation);
    for i=1:length(workers)
        if length(Worker_annotation.(workers{i})) < n_sentences
            Worker_annotation.(workers{i})(n_sentences) = empty_annotation;
        end
    end
    clear i
end