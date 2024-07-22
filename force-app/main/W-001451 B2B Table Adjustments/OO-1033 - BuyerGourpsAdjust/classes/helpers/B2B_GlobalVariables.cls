public without sharing class B2B_GlobalVariables {
    // public static Date asOf = Date.today();
    public static Date asOf;
    static {
        if (asOf == null) {
            asOf = Date.today();
        }
    }
}
