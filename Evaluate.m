function Accuracy = Evaluate(Estimates, Golds)
    labels = fieldnames(Estimates);
    n_correct = 0;
    for i = 1:length(Estimates)
        for j = 1:length(labels)
            if Estimates(i).(labels{j}) == Golds(i).(labels{j})
                n_correct = n_correct + 1;
            end
        end
    end
    n_all = i * j;
    Accuracy = n_correct/n_all;
end