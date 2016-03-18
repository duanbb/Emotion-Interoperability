function BN = LearnBN(SourceGolds, SourceTaxonomy, TargetAnnotations, TargetTaxonomy, filename) 
    source_labels = fieldnames(SourceTaxonomy);
    target_labels = fieldnames(TargetTaxonomy);
    n_sentences = length(SourceGolds);
    workers = fieldnames(TargetAnnotations);
    n_workers = length(workers);

    %% 生成事件数据cases_matrix 
    %For use with structure learning and full parameters learning.
    %(casescases_matrix(i,m) is the value of node i in case m)
    sentence_workers = GetSentenceWorkers(TargetAnnotations);
    n_cases_complete = 0;% 事件数（列数）
    for i = 1:n_sentences
       n_cases_complete = n_cases_complete + length(sentence_workers{i});
    end
    n_labels = length(source_labels) + length(target_labels);
    cases_matrix = ones(n_labels, n_cases_complete); %行：label数，列：事件数（句子数*人数）。
    % 生成source的事件（events矩阵的source部分）
    for i = 1:length(source_labels) %取出每一个source label（行）
        start_column = 1;
        for j = 1:n_sentences %取出每一个句子（列）
            end_column = start_column + length(sentence_workers{j}) - 1;
            if SourceGolds(j).(source_labels{i})
               cases_matrix(SourceTaxonomy.(source_labels{i}),start_column:end_column) = 2; %逐列（label）赋值。label的ID就是其行坐标
            end
            start_column = end_column + 1;
            clear end_column
        end
        clear j start_column
    end
    clear i
    % 生成target的事件（events矩阵的target部分）
    for i = 1:length(target_labels) %取出每个target label（行）
        cur_column = 0;
        for j = 1:n_sentences %取出每个sentence（列的第一部分）
            for k = 1:length(sentence_workers{j}) %取出每个worker（列的第二部分）
                cur_column = cur_column + 1;
                if TargetAnnotations.(sentence_workers{j}{k})(j).(target_labels{i})
                   cases_matrix(TargetTaxonomy.(target_labels{i}),cur_column) = 2; %label的ID就是其行坐标
                end
            end
            clear k
        end
        clear j cur_column
    end
    clear i
    
    %% get node_sizes
    ns = 2*ones(1,n_labels);
    
    %% learn structure
    global VARIABLES
    if strcmp(VARIABLES.struct_learning, 'K2')
        % get source label order
        source_label_freq_map = containers.Map();
        for i = 1:length(source_labels)
           source_label_freq_map(source_labels{i}) = 0;
        end
        clear i
        % 计算在各句的Gold中，各label出现的频率
        for i = 1:n_sentences %每一个句子
            for j = 1:length(source_labels) %每一个label
                if SourceGolds(i).(source_labels{j}) %当前label为true
                    source_label_freq_map(source_labels{j}) = source_label_freq_map(source_labels{j}) + 1;
                end
            end
            clear j
        end
        clear i
        source_order = Map2Order(source_label_freq_map, SourceTaxonomy);
        % get target label order
        target_label_freq_map = containers.Map();
        for i = 1:length(target_labels)
            target_label_freq_map(target_labels{i}) = 0;
        end
        clear i
        for i = 1:n_workers %取每个worker
            for j = 1:length(TargetAnnotations.(workers{i})) %取此worker的每个annotation
                cur_annotation = TargetAnnotations.(workers{i})(j);
                if ~isempty(cur_annotation) %判断此worker是否标了此sentence
                    for k = 1:length(target_labels) %取每个label
                        if cur_annotation.(target_labels{k})
                            target_label_freq_map(target_labels{k}) = target_label_freq_map(target_labels{k}) + 1;
                        end
                    end
                    clear k
                else
                    f;
                end
                clear cur_annotation
            end
            clear j
        end
        clear i
        target_order = Map2Order(target_label_freq_map, TargetTaxonomy);
        BN.Order = [source_order, target_order];
        BN.DAG = VARIABLES.struct_learning(cases_matrix, ns, BN.Order, 'max_fan_in', n_labels); %n_labels: default
    elseif strcmp(VARIABLES.struct_learning, 'MCMC')
        [dag, accept_ratio, num_edges] = learn_struct_mcmc(cases_matrix, ns);
        BN.DAG = dag{end}; %越往后越好
    else
        error('Wrong VARIABLES.struct_learning: %s', VARIABLES.struct_learning);
    end
    %g=Dag+Dag'; %一定要转成对称才能显示（对称为无向图，不对称为有向图。有向图有BUG，只能用无向图代替，但生成的图不一定是从上指向下，所以废弃。）
    %draw_graph(g, Label_names);
    all_labels = {'N_喜'; 'N_好'; 'N_安'; 'N_怒'; 'N_哀'; 'N_怖'; 'N_恥'; 'N_厭'; 'N_昂'; 'N_驚'; ...
        'E_anger'; 'E_sadness'; 'E_joy'; 'E_disgust'; 'E_surprise'; 'E_fear'};
    adj2pajek2(BN.DAG, ['Output\', filename], all_labels); %先生成文件，再导入到pajek里。(source不一定在target之前。此处要按label的本来ID顺序来排列。)
    
    %%  Learn Parameters 估计参数（条件概率）
    original_net = mk_bnet(BN.DAG, ns); %转移概率(parameters)为默认值时的NET
    for i = 1:n_labels
        original_net.CPD{i} = tabular_CPD(original_net, i);
    end
    clear i
    if strcmp(VARIABLES.params_learn, 'Complete')
        BN.Net = learn_params(original_net, cases_matrix);
    elseif strcmp(VARIABLES.params_learn, 'Missing')
        %get cases_cell
        n_cases_missing = n_sentences * n_workers; %句子数*人数
        cases_cell = cell(n_labels, n_cases_missing);
        % 生成source的事件（events矩阵的source部分）
        for i = 1:length(source_labels) %取出每一个source label（行）
            start_column = 1;
            for j = 1:n_sentences %取出每一个句子（列）
                end_column = start_column + n_workers - 1;
                if SourceGolds(j).(source_labels{i})
                    cases_cell(SourceTaxonomy.(source_labels{i}),start_column:end_column) = num2cell(2*ones(1,n_workers)); %逐列（label）赋值。label的ID就是其行坐标
                else 
                    cases_cell(SourceTaxonomy.(source_labels{i}),start_column:end_column) = num2cell(ones(1,n_workers));
                end
                start_column = end_column + 1;
                clear end_column
            end
            clear j start_column
        end
        clear i
        % 生成target的事件（events矩阵的target部分）
        for i = 1:length(target_labels) %取出每个target label（行）
            cur_column = 0;
            for j = 1:n_sentences %取出每个sentence（列的第一部分）
                for k = 1:n_workers %取出每个worker（列的第二部分）
                    cur_column = cur_column + 1;
                    if ~isempty(TargetAnnotations.(workers{k})(j).(target_labels{i}))
                        if TargetAnnotations.(workers{k})(j).(target_labels{i})
                            cases_cell{TargetTaxonomy.(target_labels{i}),cur_column} = 2; %label的ID就是其行坐标
                        else
                            cases_cell{TargetTaxonomy.(target_labels{i}),cur_column} = 1;
                        end
                    end
                end
                clear k
            end
            clear j cur_column
        end
        clear i
        
        engine = VARIABLES.inference_engine(original_net);
        BN.Net = learn_params_em(engine, cases_cell); % very slow
    else
        error('Wrong VARIABLES.params_learn: %s', VARIABLES.params_learn);
    end
    
    % 查看学习到的条件概率
    BN.CPT = cell(n_labels,1);
    for i = 1:n_labels
        s = struct(BN.Net.CPD{i}); % violate object privacy
        BN.CPT{i} = s.CPT;
        %dispcpt(Matching.CPT{i});
    end
end

%% Subfunction
function Order = Map2Order(Map, Taxonomy)
    sorted_label_freq_cell = Map2SortedCell(Map);
    labels = Map.keys;
    Order = zeros(1,length(labels));
    for i = 1:length(labels)
        Order(i) = Taxonomy.(sorted_label_freq_cell{i,1});
    end
    clear i
end