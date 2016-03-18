function WorkerAnnotation = ImportData(File, Labels, Name_column, Start_column)
    [~, textdata] = xlsread(['Input\', File]);
    system('taskkill /F /IM EXCEL.EXE'); clear ans
    workers = textdata(2:end,Name_column)';%第一行是title，要去掉
    for i = 1:length(workers) %获取每一行数据（即每个worker的数据）
        annotation_text = textdata(i+1,Start_column:end);%第一行和前两列是title，要去掉
        annotation = struct;
        annotations = cell(0);
        for j = 1:length(annotation_text)
            label_ordinal = mod(j,length(Labels)+1); %因为有一个mu，所以要加1
            if label_ordinal == 0
                %worker_annotation.(workers{i})
                 annotations{j/(length(Labels)+1),1} = annotation; %cell在动态地变，按列存储
                 clear annotation
                 continue
            end
            cur_label = Labels{label_ordinal};
            if strcmp(annotation_text{j},'') %0:false, 1:true
                annotation.(cur_label) = false;
            else
                annotation.(cur_label) = true;
            end
            clear cur_label label_ordinal
        end
        clear j annotation_text
        WorkerAnnotation.(workers{i}) = CellArray2StructArray(annotations);
    end
    clear i
end