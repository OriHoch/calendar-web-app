from datapackage_pipelines.wrapper import ingest, spew

parameters, datapackage, resources = ingest()
stats = {}

def new_resource_iterator(resource_iterator_):
    def resource_processor(resource_):
        for row in resource_:
            stats['row-count'] += 1
            yield row

    for resource in resource_iterator_:
        yield resource_processor(resource)

def parse_name(descriptor, row):
    for field in descriptor["schema"]["fields"]:
        if "original_name" in field:
            val = row.pop(field["original_name"])
            row[field["name"]] = val

def parse_when(row):
    row["when_from"], row["when_to"] = "", ""
    if row.get("when") and len(row["when"]) > 3:
        tmp = row["when"].split('-')
        if len(tmp) == 2:
            row["when_from"], row["when_to"] = tmp
            row["when"] = ""

def parse_source(row):
    row["source_link"] = ""
    if row.get("source") and "http" in row["source"]:
        tmp = row["source"].split("http")
        row["source"] = tmp[0]
        row["source_link"] = "http" + tmp[1].strip()

def filter_row(descriptor, row):
    parse_name(descriptor, row)
    parse_when(row)
    parse_source(row)
    yield row

def filter_resource(descriptor, resource):
    for row in resource:
        yield from filter_row(descriptor, row)

def filter_resources():
    for descriptor, resource in zip(datapackage["resources"], resources):
        yield filter_resource(descriptor, resource)

for resource in datapackage["resources"]:
    schema = resource["schema"]
    for field in schema["fields"]:
        if "_name" in field:
            field["original_name"] = field.pop("name")
            field["name"] = field.pop("_name")
    schema["fields"] += [{"name": "when_from", "type": "string"},
                         {"name": "when_to", "type": "string"},
                         {"name": "source_link", "type": "string"}]

spew(datapackage, filter_resources(), stats)
