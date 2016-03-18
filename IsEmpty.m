%判断此worker是否标了此sentence
function empty = IsEmpty(Annotation)
    labels = fieldnames(Annotation);
    if isempty(Annotation.(labels{1}))
        empty = true;
    else
        empty = false;
    end
end