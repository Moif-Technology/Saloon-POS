/// Until KOT APIs exist on Moifone `api/`, widgets expect this map shape.
Future<Map<String, dynamic>> emptyKotDetails() async => {
      'success': true,
      'data': <dynamic>[],
    };
