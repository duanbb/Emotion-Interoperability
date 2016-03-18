function StructArray = CellArray2StructArray(CellArray)
    labels = fieldnames(CellArray{1});
    n_elements = length(CellArray);
    StructArray(n_elements) = struct;
    %要先建立struct的结构
    for i = 1:length(labels)
       StructArray(n_elements).(labels{i}) = [];
    end
    clear i
    
    for i = 1:n_elements
        StructArray(i) = CellArray{i};
    end
    clear i
end