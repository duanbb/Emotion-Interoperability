function Worker_annotation = IntegrateData(Worker_annotation_cell, Start_array)
    for i = 1:length(Worker_annotation_cell) %ȡ��ÿһ�����ݼ�
        workers = fieldnames(Worker_annotation_cell{i});
        for j = 1:length(workers) %ȡ��ÿ��worker������
            for k = 1:length(Worker_annotation_cell{i}.(workers{j})) %ȡ����worker��ÿ��annotation
                Worker_annotation.(workers{j})(k + Start_array(i) - 1, 1) = Worker_annotation_cell{i}.(workers{j})(k);% ���д洢
            end
        end
        clear j
    end
    clear i
    
    %���ɲ�ȫ�õ�annotations
    labels = fieldnames(Worker_annotation.(workers{1})(1));
    empty_annotation = EmptyAnnotation(labels);
    
    n_sentences = k + Start_array(end) - 1; %���һ�����ݼ������ݸ��� + ���һ�����ݼ�����ʼλ�� - 1
    workers = fieldnames(Worker_annotation);
    for i=1:length(workers)
        if length(Worker_annotation.(workers{i})) < n_sentences
            Worker_annotation.(workers{i})(n_sentences) = empty_annotation;
        end
    end
    clear i
end