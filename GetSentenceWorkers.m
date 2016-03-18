%统计每句话被哪些worker标过。
function SentenceWorkers = GetSentenceWorkers(Annotations)
    workers = fieldnames(Annotations);
    SentenceWorkers = cell(length(Annotations.(workers{1})),1);
    for i = 1:length(SentenceWorkers) %sentence 
        for j = 1:length(workers) % worker
            if ~IsEmpty(Annotations.(workers{j})(i))
                if isempty(SentenceWorkers{i})
                    SentenceWorkers{i} = workers(j); %第一个要先封装成cell，所以要用()，不能用{}
                else
                    SentenceWorkers{i} = [SentenceWorkers{i}; workers{j}];
                end
            end
        end
        clear j
    end
    clear i
end