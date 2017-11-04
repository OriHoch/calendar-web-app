import os, yaml, logging
from jinja2 import Environment, FileSystemLoader, select_autoescape
from datapackage_pipelines.wrapper import ingest, spew
from collections import OrderedDict
from copy import deepcopy


def get_jinja_env():
    return Environment(
        loader=FileSystemLoader('templates'),
        autoescape=select_autoescape(['html', 'xml'])
    )


def get_jinja_template(jinja_env, template_name):
    return jinja_env.get_template(template_name)


def build_template(jinja_env, template_name, context, output_name=None):
    if output_name is None:
        output_name = template_name
    dist_file_name = os.path.join("dist", output_name)
    logging.info("Building template {} to {}".format(template_name, dist_file_name))
    template = get_jinja_template(jinja_env, template_name)
    with open(dist_file_name, "w") as f:
        f.write(template.render(context))


def get_sort_key(row):
    sort_key = row["date"].strftime("%Y-%m-%d")
    if row.get("when_from"):
        sort_key += "-"+row["when_from"]
    elif row.get("when"):
        sort_key += "-"+row["when"]
    return sort_key


def init_dates(cur_date, all_appointment_dates):
    logging.info("-- {}".format(cur_date.strftime('%Y-%m-%d')))
    appointment_dates = [{"date": cur_date, "appointments": []}]
    all_appointment_dates.append(appointment_dates)
    return cur_date, appointment_dates


def get_page(page_num, all_appointment_dates):
    if page_num-1 < 0 or page_num > len(all_appointment_dates):
        return None
    else:
        appointment_dates = all_appointment_dates[page_num-1]
        first_date = appointment_dates[0]["date"]
        last_date = appointment_dates[-1]["date"]
        return {"num": page_num,
                "title": "{} - {}".format(first_date.strftime("%d/%m/%Y"), last_date.strftime("%d/%m/%Y")),
                "url": get_page_output_filename(page_num, all_appointment_dates)}


def get_page_output_filename(page_num, all_appointment_dates):
    appointment_dates = all_appointment_dates[page_num - 1]
    if page_num == 1:
        return "index.html"
    else:
        return "{}.html".format(appointment_dates[0]["date"].strftime('%Y-%m-%d'))

def main():
    parameters, datapackage, resources = ingest()
    stats = {}
    all_rows = []
    for descriptor, resource in zip(datapackage["resources"], resources):
        for row in resource:
            all_rows.append(row)
    all_appointment_dates = []
    appointment_dates = []
    for row_num, row in enumerate(sorted(all_rows, key=get_sort_key, reverse=True)):
        if len(appointment_dates) == 0:
            cur_date, appointment_dates = init_dates(row["date"], all_appointment_dates)
        elif appointment_dates[-1]["date"] != row["date"]:
            if sum([len(d["appointments"]) for d in appointment_dates]) >= parameters["appointments-per-page"]:
                cur_date, appointment_dates = init_dates(row["date"], all_appointment_dates)
            else:
                appointment_dates.append({"date": row["date"], "appointments": []})
        if not row.get("when") and row.get("when_from"):
            if row.get("when_to"):
                row["when"] = "{}-{}".format(row["when_from"], row["when_to"])
            else:
                row["when"] = row["when_from"]
        row["bg"] = str(row_num%2+1)
        row["month_heb"] = ["ינואר", "פברואר", "מרץ", "אפריל", "מאי", "יוני", "יולי",
                            "אוגוסט", "ספטמבר", "אוקטובר", "נובמבר", "דצמבר"][row["date"].month-1]
        appointment_dates[-1]["appointments"].append(row)
    jinja_env = get_jinja_env()
    context = parameters["context"]
    first_page = get_page(1, all_appointment_dates)
    last_page = get_page(len(all_appointment_dates), all_appointment_dates)
    for page_num, appointment_dates in enumerate(all_appointment_dates, start=1):
        if len(appointment_dates) > 0:
            context["dates"] = appointment_dates
            context["pages"] = {"first": first_page,
                                "prev": get_page(page_num-1, all_appointment_dates),
                                "cur": get_page(page_num, all_appointment_dates),
                                "next": get_page(page_num+1, all_appointment_dates),
                                "last": last_page}
            output_file_name = get_page_output_filename(page_num, all_appointment_dates)
            build_template(jinja_env, "appointments.html", context, output_file_name)
    spew({}, [], stats)


if __name__ == "__main__":
    main()
