import 'package:country_state_city/country_state_city.dart' as csc;

class CountrySubdivisionService {
  Future<List<csc.Country>>? _countries;

  Future<List<String>> subdivisionsFor(String countryName) async {
    final countries = await (_countries ??= csc.getAllCountries());
    final normalizedName = _normalize(
      _countryAliases[countryName] ?? countryName,
    );
    csc.Country? match;
    for (final country in countries) {
      if (_normalize(country.name) == normalizedName) {
        match = country;
        break;
      }
    }
    if (match == null) return const [];

    final states = await csc.getStatesOfCountry(match.isoCode);
    final names =
        states
            .map((state) => state.name.trim())
            .where((name) {
              return name.isNotEmpty;
            })
            .toSet()
            .toList()
          ..sort();
    return names;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp('[^a-z0-9]'), '');
}

const Map<String, String> _countryAliases = {
  'British Indian Ocean Terr': 'British Indian Ocean Territory',
  'British Virgin Islands': 'Virgin Islands (British)',
  'Congo, Democratic Repub': 'Congo The Democratic Republic Of The',
  "Cote d'Ivoire": "Cote D'Ivoire (Ivory Coast)",
  'Croatia': 'Croatia (Hrvatska)',
  'Falkland Is. Islas Malvinas': 'Falkland Islands',
  'Fiji': 'Fiji Islands',
  'Guernsey': 'Guernsey and Alderney',
  'Heard Is. & McDonald Is.': 'Heard Island and McDonald Islands',
  'Hong Kong': 'Hong Kong S.A.R.',
  'Macau': 'Macau S.A.R.',
  'Micronesia, Fed States of': 'Micronesia',
  'Netherlands': 'Netherlands The',
  'North Korea': 'Korea North',
  'Pitcairn Islands': 'Pitcairn Island',
  'Saint Martin': 'Saint-Martin (French part)',
  'Saint Vincent & Grenadine': 'Saint Vincent And The Grenadines',
  'So.Georgia/So.Sandwich Is': 'South Georgia',
  'South Korea': 'Korea South',
  'Svalbard': 'Svalbard And Jan Mayen Islands',
  'Vatican City': 'Vatican City State (Holy See)',
  'Wallis and Futuna': 'Wallis And Futuna Islands',
  'West Bank': 'Palestinian Territory Occupied',
};
