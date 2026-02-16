#parse("Apex File Header.cls")

@IsTest
private class ${NAME}
{
    @TestSetup
    static void setup() {
        Account account = new Account(
            Name = 'Test'
        );

        insert account;
    }

    @IsTest
    static void shouldReturnWhenCalled()
    {
        /* Arrange */

        List<SObject> = [SELECT Id FROM Account];
        Object result;

        /* Act */

        Test.startTest();
        try {
            ${NAME}.method();
        } catch (Exception e) {
            result = Assert.fail(e.getMessage() + '\n' + e.getStackTraceString());
        }
        Test.stopTest();

        /* Assert */

        Assert.areNotEqual(null, result);
    }
}