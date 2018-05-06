package org.yinwang.yin.ast;


import org.yinwang.yin.Scope;
import org.yinwang.yin._;
import org.yinwang.yin.value.RecordType;
import org.yinwang.yin.value.RecordValue;
import org.yinwang.yin.value.Value;

public class Attr extends Node {
    public Node value;
    public Name attr;


    public Attr(Node value, Name attr, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.value = value;
        this.attr = attr;
    }


    @Override
    public Value interp(Scope s) {
        Value record = value.interp(s);
        if (record instanceof RecordValue) {
            Value a = ((RecordValue) record).properties.lookupLocal(attr.id);
            if (a != null) {
                return a;
            } else {
                _.abort(attr, "attribute " + attr + " not found in record: " + record);
                return null;
            }
        } else {
            _.abort(attr, "getting attribute of non-record: " + record);
            return null;
        }
    }


    @Override
    public Value typecheck(Scope s) {
        Value record = value.typecheck(s);
        if (record instanceof RecordValue) {
            Value a = ((RecordValue) record).properties.lookupLocal(attr.id);
            if (a != null) {
                return a;
            } else {
                _.abort(attr, "attribute " + attr + " not found in record: " + record);
                return null;
            }
        } else {
            _.abort(attr, "getting attribute of non-record: " + record);
            return null;
        }
    }


    public void set(Value v, Scope s) {
        Value record = value.interp(s);
        if (record instanceof RecordType) {
            Value a = ((RecordType) record).properties.lookup(attr.id);
            if (a != null) {
                ((RecordType) record).properties.putValue(attr.id, v);
            } else {
                _.abort(attr, "can only assign to existing attribute in record, " + attr + " not found in: " + record);
            }
        } else {
            _.abort(attr, "setting attribute of non-record: " + record);
        }
    }


    public String toString() {
        return value + "." + attr;
    }

}
