// Write our own (safe) getters and setters for attr and value
// in order to avoid warnings
//
%ignore hyperclient_attribute::attr;
%ignore hyperclient_attribute::value;

%typemap(javacode) hyperclient_attribute
%{
  public String getAttrName()
  {
    return HyperClient.read_attr_name(this);
  }

  private byte[] getAttrValueBytes()
  {
    int bytes_sz = HyperClient.size_t_to_int(getValue_sz());

    return getAttrValueBytes(0,bytes_sz);
  }

  private byte[] getAttrValueBytes(long pos, int size)
  {
    byte[] bytes = new byte[size];
    HyperClient.read_attr_value(this,bytes,pos);
    return bytes;
  }

  private java.lang.Object getAttrStringValue()
  {
    return new String(getAttrValueBytes());
  }

  private byte[] zerofill(byte[] inbytes)
  {
    byte[] outbytes = new byte[8];

    // Make sure outbytes is initialized to 0
    for (int i=0; i<8; i++ ) outbytes[i] = 0;

    // Copy little-endingly
    for (int i=0; i<inbytes.length; i++) outbytes[i] = inbytes[i];

    return outbytes;
  }

  private java.lang.Object getAttrLongValue()
  {
    byte[] bytes = getAttrValueBytes();

    if ( bytes.length < 8  )
    {
        bytes = zerofill(bytes);
    }

    return new Long( java.nio.ByteBuffer.wrap(bytes).order(
                    java.nio.ByteOrder.LITTLE_ENDIAN).getLong());
  }

  private java.lang.Object getAttrDoubleValue()
  {
    byte[] bytes = getAttrValueBytes();

    if ( bytes.length < 8 )
    {
        bytes = zerofill(bytes);
    }

    return new Double(java.nio.ByteBuffer.wrap(bytes).order(
                    java.nio.ByteOrder.LITTLE_ENDIAN).getDouble());
  }

  private java.lang.Object getAttrCollectionStringValue(
            java.util.AbstractCollection<String> coll) throws ValueError
  {
    String collType = coll instanceof java.util.List?"list":"set"; 

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger four = new java.math.BigInteger("4");

    int coll_sz = 0; 

    while ( rem.compareTo(four) >= 0 && coll_sz <= Integer.MAX_VALUE )
    {
        int sz
          = java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,4)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getInt();

        java.math.BigInteger sz_bi
          = new java.math.BigInteger(new Integer(sz).toString());

        if ( rem.subtract(four).compareTo(sz_bi) < 0 ) 
        {
            throw new ValueError(collType
                        + "(string) is improperly structured (file a bug)");
        }
   
        coll.add(new String(getAttrValueBytes(pos+4,sz)));

        rem = rem.subtract(four).subtract(sz_bi);        
        pos = value_sz.subtract(rem).longValue();

        coll_sz += 1;
    }

    if ( coll_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError(collType + "(string) contains excess data (file a bug)");
    }    

    return coll;
  }

  private java.lang.Object getAttrCollectionLongValue(
            java.util.AbstractCollection<Long> coll) throws ValueError
  {
    String collType = coll instanceof java.util.List?"list":"set"; 

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger eight = new java.math.BigInteger("8");

    int coll_sz = 0; 

    while ( rem.compareTo(eight) >= 0 && coll_sz <= Integer.MAX_VALUE )
    {
        coll.add(new Long(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getLong()));

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        coll_sz += 1;
    }

    if ( coll_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError(collType + "(int64) contains excess data (file a bug)");
    }    

    return coll;
  }

  private java.lang.Object getAttrCollectionDoubleValue(
            java.util.AbstractCollection<Double> coll) throws ValueError
  {
    String collType = coll instanceof java.util.List?"list":"set"; 

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger eight = new java.math.BigInteger("8");

    int coll_sz = 0; 

    while ( rem.compareTo(eight) >= 0 && coll_sz <= Integer.MAX_VALUE )
    {
        coll.add(new Double(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getDouble()));

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        coll_sz += 1;
    }

    if ( coll_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError(collType + "(float) contains excess data (file a bug)");
    }    

    return coll;
  }

  private java.lang.Object getAttrMapStringStringValue() throws ValueError
  {
    java.util.HashMap<String,String> map = new java.util.HashMap<String,String>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger four = new java.math.BigInteger("4");

    int map_sz = 0; 

    while ( rem.compareTo(four) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        int sz
          = java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,4)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getInt();

        java.math.BigInteger sz_bi
          = new java.math.BigInteger(new Integer(sz).toString());

        if ( rem.subtract(four).compareTo(sz_bi) < 0 ) 
        {
            throw new ValueError(
                        "map(string,string) is improperly structured (file a bug)");
        }
   
        String key = new String(getAttrValueBytes(pos+4,sz)); 

        rem = rem.subtract(four).subtract(sz_bi);        
        pos = value_sz.subtract(rem).longValue();

        sz = java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,4)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getInt();

        sz_bi = new java.math.BigInteger(new Integer(sz).toString());

        if ( rem.subtract(four).compareTo(sz_bi) < 0 ) 
        {
            throw new ValueError(
                        "map(string,string) is improperly structured (file a bug)");
        }

        String val = new String(getAttrValueBytes(pos+4,sz));

        rem = rem.subtract(four).subtract(sz_bi);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(string,string) contains excess data (file a bug)");
    }    

    return map;
  }

  private java.lang.Object getAttrMapStringLongValue() throws ValueError
  {
    java.util.HashMap<String,Long> map = new java.util.HashMap<String,Long>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger four = new java.math.BigInteger("4");
    java.math.BigInteger eight = new java.math.BigInteger("8");

    int map_sz = 0; 

    while ( rem.compareTo(four) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        int sz
          = java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,4)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getInt();

        java.math.BigInteger sz_bi
          = new java.math.BigInteger(new Integer(sz).toString());

        if ( rem.subtract(four).compareTo(sz_bi) < 0 ) 
        {
            throw new ValueError(
                        "map(string,int64) is improperly structured (file a bug)");
        }
   
        String key = new String(getAttrValueBytes(pos+4,sz)); 

        rem = rem.subtract(four).subtract(sz_bi);        
        pos = value_sz.subtract(rem).longValue();

        if ( rem.compareTo(eight) < 0 ) 
        {
            throw new ValueError(
                        "map(string,int64) is improperly structured (file a bug)");
        }

        Long val = new Long(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getLong());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(string,int64) contains excess data (file a bug)");
    }    

    return map;
  }

  private java.lang.Object getAttrMapStringDoubleValue() throws ValueError
  {
    java.util.HashMap<String,Double> map = new java.util.HashMap<String,Double>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger four = new java.math.BigInteger("4");
    java.math.BigInteger eight = new java.math.BigInteger("8");

    int map_sz = 0; 

    while ( rem.compareTo(four) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        int sz
          = java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,4)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getInt();

        java.math.BigInteger sz_bi
          = new java.math.BigInteger(new Integer(sz).toString());

        if ( rem.subtract(four).compareTo(sz_bi) < 0 ) 
        {
            throw new ValueError(
                        "map(string,float) is improperly structured (file a bug)");
        }
   
        String key = new String(getAttrValueBytes(pos+4,sz)); 

        rem = rem.subtract(four).subtract(sz_bi);        
        pos = value_sz.subtract(rem).longValue();

        if ( rem.compareTo(eight) < 0 ) 
        {
            throw new ValueError(
                        "map(string,float) is improperly structured (file a bug)");
        }

        Double val = new Double(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getDouble());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(string,float) contains excess data (file a bug)");
    }    

    return map;
  }

  private java.lang.Object getAttrMapLongStringValue() throws ValueError
  {
    java.util.HashMap<Long,String> map = new java.util.HashMap<Long,String>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger four = new java.math.BigInteger("4");
    java.math.BigInteger eight = new java.math.BigInteger("8");

    int map_sz = 0; 

    while ( rem.compareTo(eight) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        Long key = new Long(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getLong());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        int sz
          = java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,4)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getInt();

        java.math.BigInteger sz_bi
          = new java.math.BigInteger(new Integer(sz).toString());

        if ( rem.subtract(four).compareTo(sz_bi) < 0 ) 
        {
            throw new ValueError(
                        "map(int64,string) is improperly structured (file a bug)");
        }
   
        String val = new String(getAttrValueBytes(pos+4,sz)); 

        rem = rem.subtract(four).subtract(sz_bi);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(int64,string) contains excess data (file a bug)");
    }    

    return map;
  }

  private java.lang.Object getAttrMapLongLongValue() throws ValueError
  {
    java.util.HashMap<Long,Long> map = new java.util.HashMap<Long,Long>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger eight = new java.math.BigInteger("8");
    java.math.BigInteger sixteen = new java.math.BigInteger("16");

    int map_sz = 0; 

    while ( rem.compareTo(sixteen) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        Long key = new Long(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getLong());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        Long val = new Long(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getLong());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(int64,int64) contains excess data (file a bug)");
    }    

    return map;
  }

  private java.lang.Object getAttrMapLongDoubleValue() throws ValueError
  {
    java.util.HashMap<Long,Double> map = new java.util.HashMap<Long,Double>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger eight = new java.math.BigInteger("8");
    java.math.BigInteger sixteen = new java.math.BigInteger("16");

    int map_sz = 0; 

    while ( rem.compareTo(sixteen) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        Long key = new Long(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getLong());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        Double val = new Double(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getDouble());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(int64,float) contains excess data (file a bug)");
    }    

    return map;
  }

  private java.lang.Object getAttrMapDoubleStringValue() throws ValueError
  {
    java.util.HashMap<Double,String> map = new java.util.HashMap<Double,String>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger four = new java.math.BigInteger("4");
    java.math.BigInteger eight = new java.math.BigInteger("8");

    int map_sz = 0; 

    while ( rem.compareTo(eight) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        Double key = new Double(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getDouble());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        int sz
          = java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,4)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getInt();

        java.math.BigInteger sz_bi
          = new java.math.BigInteger(new Integer(sz).toString());

        if ( rem.subtract(four).compareTo(sz_bi) < 0 ) 
        {
            throw new ValueError(
                        "map(float,string) is improperly structured (file a bug)");
        }
   
        String val = new String(getAttrValueBytes(pos+4,sz)); 

        rem = rem.subtract(four).subtract(sz_bi);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(float,string) contains excess data (file a bug)");
    }    

    return map;
  }

  private java.lang.Object getAttrMapDoubleLongValue() throws ValueError
  {
    java.util.HashMap<Double,Long> map = new java.util.HashMap<Double,Long>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger eight = new java.math.BigInteger("8");
    java.math.BigInteger sixteen = new java.math.BigInteger("16");

    int map_sz = 0; 

    while ( rem.compareTo(sixteen) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        Double key = new Double(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getDouble());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        Long val = new Long(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getLong());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(float,int64) contains excess data (file a bug)");
    }    

    return map;
  }

  private java.lang.Object getAttrMapDoubleDoubleValue() throws ValueError
  {
    java.util.HashMap<Double,Double> map = new java.util.HashMap<Double,Double>();    

    // Interpret return value of getValue_sz() as unsigned
    //
    java.math.BigInteger value_sz 
        = new java.math.BigInteger(1,java.nio.ByteBuffer.allocate(8).order(
            java.nio.ByteOrder.BIG_ENDIAN).putLong(getValue_sz()).array());

    java.math.BigInteger rem = new java.math.BigInteger(value_sz.toString());
    long pos = 0;

    java.math.BigInteger eight = new java.math.BigInteger("8");
    java.math.BigInteger sixteen = new java.math.BigInteger("16");

    int map_sz = 0; 

    while ( rem.compareTo(sixteen) >= 0 && map_sz <= Integer.MAX_VALUE )
    {
        Double key = new Double(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getDouble());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        Double val = new Double(java.nio.ByteBuffer.wrap(getAttrValueBytes(pos,8)).order(
                        java.nio.ByteOrder.LITTLE_ENDIAN).getDouble());

        rem = rem.subtract(eight);        
        pos = value_sz.subtract(rem).longValue();

        map.put(key,val);

        map_sz += 1;
    }

    if ( map_sz < Integer.MAX_VALUE && rem.compareTo(java.math.BigInteger.ZERO) > 0 )
    {
        throw new ValueError("map(float,float) contains excess data (file a bug)");
    }    

    return map;
  }

  public java.lang.Object getAttrValue() throws ValueError
  {
    switch(getDatatype())
    {
      case HYPERDATATYPE_STRING:
        return getAttrStringValue();

      case HYPERDATATYPE_INT64:
        return getAttrLongValue();

      case HYPERDATATYPE_FLOAT:
        return getAttrDoubleValue();

      case HYPERDATATYPE_LIST_STRING:
        java.util.Vector<String> ls = new java.util.Vector<String>();
        getAttrCollectionStringValue(ls);
        return ls;

      case HYPERDATATYPE_LIST_INT64:
        java.util.Vector<Long> li = new java.util.Vector<Long>();
        getAttrCollectionLongValue(li);
        return li;

      case HYPERDATATYPE_LIST_FLOAT:
        java.util.Vector<Double> lf = new java.util.Vector<Double>();
        getAttrCollectionDoubleValue(lf);
        return lf;

      case HYPERDATATYPE_SET_STRING:
        java.util.HashSet<String> ss = new java.util.HashSet<String>();
        getAttrCollectionStringValue(ss);
        return ss;

      case HYPERDATATYPE_SET_INT64:
        java.util.HashSet<Long> si = new java.util.HashSet<Long>();
        getAttrCollectionLongValue(si);
        return si;

      case HYPERDATATYPE_SET_FLOAT:
        java.util.HashSet<Double> sf = new java.util.HashSet<Double>();
        getAttrCollectionDoubleValue(sf);
        return sf;

      case HYPERDATATYPE_MAP_STRING_STRING:
        return getAttrMapStringStringValue();

      case HYPERDATATYPE_MAP_STRING_INT64:
        return getAttrMapStringLongValue();

      case HYPERDATATYPE_MAP_STRING_FLOAT:
        return getAttrMapStringDoubleValue();

      case HYPERDATATYPE_MAP_INT64_STRING:
        return getAttrMapLongStringValue();

      case HYPERDATATYPE_MAP_INT64_INT64:
        return getAttrMapLongLongValue();

      case HYPERDATATYPE_MAP_INT64_FLOAT:
        return getAttrMapLongDoubleValue();

      case HYPERDATATYPE_MAP_FLOAT_STRING:
        return getAttrMapDoubleStringValue();

      case HYPERDATATYPE_MAP_FLOAT_INT64:
        return getAttrMapDoubleLongValue();

      case HYPERDATATYPE_MAP_FLOAT_FLOAT:
        return getAttrMapDoubleDoubleValue();

      default:
        throw new ValueError("Server returned garbage value (file a bug)");
    }
  }
%}