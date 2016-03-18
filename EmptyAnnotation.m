function Annotation = EmptyAnnotation(labels)
    for i = 1:length(labels)
        Annotation.(labels{i}) = [];
    end
    clear i
end