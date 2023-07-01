import json
import os

dir_path = os.getcwd()
print(dir_path)

with open(dir_path + '/anima_metadata.json', 'r') as f:
  data = json.load(f)

async def run(nre):
         packed_data_batch = batch_pack_anima()

         for e in packed_data_batch:
            print(e)

# BATCH DATA FOR 50 ANIMA
def batch_pack_anima(start_id):
    packed_data_batch = []
    for i in range(start_id-1, start_id + 50 -1):
        anima_data_raw = data["list"][i]
        anima_attributes = get_anima_attributes(anima_data_raw)
        packed_data = pack_anima_data(anima_attributes)    

        packed_data_batch.append(packed_data)
    return packed_data_batch
# Packing functions

def get_anima_attributes(raw_data):
    anima_attributes = []
    for attribute in raw_data["attributes"]:
        attribute_name = attribute["trait_type"]     
        if attribute_name == "Type":
            continue 

        attribute_value = attribute["value"]
        anima_attributes.append(attribute_value)

    return anima_attributes

def pack_anima_data(anima_attributes):
    packed_data = 0
    for i, value in enumerate(anima_attributes):
        #print(value)
        packed_data = (value << (i * 8)) | packed_data 
    #print(packed_data)
    return packed_data

def get_anima_attribute(id, attribute):
    anima_data_raw = data["list"][id-1]
    anima_attributes = get_anima_attributes(anima_data_raw)
    return anima_attributes[attribute]