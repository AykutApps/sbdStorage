public class BecomeDealerCtrl {
    public List<String> brands { get; set; }
    public Map<String, Boolean> brandSelected { get; set; }

    public List<String> otherProducts { get; set; }
    public Map<String, Boolean> otherProductsSelected { get; set; }

    public Map<String, Boolean> valueMap { get; set; }
    public String comment { get; set; } // Property for the free text field

    public BecomeDealerCtrl() {
        comment = '';
        brands = new List<String>{
            'Arctic Cat',
            'Ariens / Gravely',
            'Bad Boy',
            'Bearcat',
            'BobCat',
            'Branson',
            'Briggs and Stratton',
            'Case',
            'Country Clipper',
            'CountyLine',
            'Cub Cadet',
            'Cub Commercial',
            'Dixie Chopper',
            'Dolmar',
            'Echo',
            'Exmark',
            'Ferris',
            'Grasshopper',
            'Honda',
            'Husqvarna',
            'Hustler',
            'John Deere',
            'Kawasaki',
            'Kioti',
            'Kubota',
            'Mahindra',
            'Mantis',
            'MTD',
            'Murray',
            'New Holland',
            'Polaris',
            'Poulan',
            'SCAG',
            'Shindiawa',
            'Snapper',
            'Snapper PRO',
            'STIHL',
            'Swisher',
            'Toro',
            'Troybilt',
            'White Outdoor',
            'Woods Mow-n-machine',
            'World Lawn',
            'Wright',
            'Yamaha',
            'Yanmar'
        };

        // Initialize the map
        brandSelected = new Map<String, Boolean>();
        for (String brand : brands) {
            brandSelected.put(brand, false);
        }

        otherProducts = new List<String>{ 'Zero-Turn Lawn Mowers', 'Push Mowers', 'ATV/UTV', 'Snow Removal Equipment', 'General Hardware and Supplies', 'Other' };

        // Initialize the map
        otherProductsSelected = new Map<String, Boolean>();
        for (String op : otherProducts) {
            otherProductsSelected.put(op, false);
        }

        valueMap = new Map<String, Boolean>();
        valueMap.put('displayArea', false);
        valueMap.put('serviceArea', false);
        valueMap.put('partsArea', false);
        valueMap.put('temp1', false);
        valueMap.put('temp2', false);
    }

    public void submit() {
        // Logic to execute when the button is clicked
        System.debug('Button clicked');
        System.debug(this.comment);
        System.debug(this.valueMap);
        System.debug(this.otherProductsSelected);
        System.debug(this.brandSelected);
    }
}
