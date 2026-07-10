import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_letter_signer/core/location/country_subdivision_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads subdivisions for countries by PDF display name', () async {
    final service = CountrySubdivisionService();

    final canadianProvinces = await service.subdivisionsFor('Canada');
    final unitedStatesAreas = await service.subdivisionsFor('United States');

    expect(canadianProvinces, contains('Ontario'));
    expect(canadianProvinces, contains('Quebec'));
    expect(unitedStatesAreas, contains('California'));
    expect(unitedStatesAreas, contains('New York'));
  });

  test('returns an empty list when a country has no dataset match', () async {
    final service = CountrySubdivisionService();

    expect(await service.subdivisionsFor('Unknown country'), isEmpty);
  });
}
