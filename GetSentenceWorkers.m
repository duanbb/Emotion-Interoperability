%ͳ��ÿ�仰����Щworker�����
function SentenceWorkers = GetSentenceWorkers(Annotations)
    workers = fieldnames(Annotations);
    SentenceWorkers = cell(length(Annotations.(workers{1})),1);
    for i = 1:length(SentenceWorkers) %sentence 
        for j = 1:length(workers) % worker
            if ~IsEmpty(Annotations.(workers{j})(i))
                if isempty(SentenceWorkers{i})
                    SentenceWorkers{i} = workers(j); %��һ��Ҫ�ȷ�װ��cell������Ҫ��()��������{}
                else
                    SentenceWorkers{i} = [SentenceWorkers{i}; workers{j}];
                end
            end
        end
        clear j
    end
    clear i
end