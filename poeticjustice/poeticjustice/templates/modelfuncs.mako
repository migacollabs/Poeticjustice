<%def name="add_entity_value(entity, field_name)">
    % if entity:
        % if entity[field_name] is not None:
            value="${entity[field_name]}"
        % endif
    % endif
</%def>

<%def name="html5_form_items_for_model(model, ord_flds, entity)">
    % for field_name in ord_flds:
        <tr>
            <td><h5 class="subheader">${field_name}</h5></td>
            <td><h5 class="subheader">${model[field_name]['fld_def'].pytype}</h5></td>
            <td><h5 class="subheader">size="${model[field_name]['fld_def'].length}"</h5></td>
            <td><h5 class="subheader">
                <input
                    type="${model[field_name]['fld_def'].formtype}"
                    name="${field_name}"
                    size="64"
                    ${add_entity_value(entity, field_name)}
                    ${model[field_name]['fld_def'].opt_text}
                >
            </h5></td>
            <td><h5 class="subheader">${model[field_name]['fld_def'].opt_text}</h5></td>
        </tr>
    % endfor
</%def>

<%def name="model_form(model_name, model, ordered_fields, entity, method, table_width, border, submit_type, submit_value)">
    <form action="/m/edit/${model_name}" method="${method}">
        <table>
            <thead>
            <tr>
                <th width="200">Field</th>
                <th width="200">Type</th>
                <th width="200">Size</th>
                <th width="350">Value</th>
                <th width="100">Required</th>
            </tr>
            </thead>
            <tbody>
            ${html5_form_items_for_model(model, ordered_fields, entity)}
            <tr>
                <td>
                    <input type='hidden' name='override_method' value="${override_method}" />
                </td>
            </tr>
            </tbody>
        </table>
        <input type="${submit_type}" value="${submit_value}" class="button expand">
    </form>
</%def>
