# CGPM Project Memory

## Key Patterns
- **Trigger Framework**: Kevin O'Hara's TriggerHandler. Handlers extend it, override before/afterInsert/Update/Delete. Framework auto-dispatches via `run()`.
- **Action System**: `@InvocableMethod` classes (ActionRequest→ActionResponse). Server-side via `Invocable.Action.createCustomAction('apex', className)`. Flows via `Flow.Interview.createInterview()`.
- **TriggerActionService**: Central service executing Template_Action__c from triggers. Recursion guard via `static Set<String> activeContexts`. Before→addError(), After→debug log.
- **TemplateSelector**: All action/status configs cached per template ID. `getActionConfigs(Set<Id>)` and `getActionConfigsForProject(Set<Id>)`.
- **TestDataFactory**: Uses `insert as user` pattern. Has overloads for action configs with/without templateStatusId.
- **LWC Tests**: Jest-based, use `flushPromises()`, mock dataManager/actionExecutor via `element.shadowRoot.querySelector()`.

## Gotchas
- Stray text in files: Always verify file content after edits—especially if the plan transcript had inline code suggestions that could leak.
- recordDetails.js line 66 had stray text "move the action ex" from plan context—caught via test failure.
- Work Item tests: `Work_Item_Name__c` field isn't rendered unless the field config includes it as editable. Don't assume DOM elements exist.
- Triggers already had all 6 operations (before/after insert/update/delete). Check before modifying trigger files.
- **Namespace in objectApiName**: In packaging org, `objectApiName` arrives WITHOUT namespace prefix (e.g., `Work_Item__c` not `cgpm__Work_Item__c`). Use `endsWith('Work_Item__c')` not `=== 'cgpm__Work_Item__c'`.
- **Deploy command**: Always use `npm run source:push`, never `sf project deploy start` directly. Default target org is `cgpm-dev` (scratch org).
- **Status-linked indirect path**: When configs (field/action) link only via `Template_Status__c` (null direct template lookup), ALL layers need the indirect path: Selector WHERE clause, Selector groupId ternary, Service groupId ternary, AND trigger handler collectTemplateIds. Miss any layer and the feature silently fails.

## File Locations
- Services: `src/main/logic/classes/services/`
- Trigger handlers: `src/main/logic/classes/triggers/`
- Triggers: `src/main/logic/triggers/`
- Actions: `src/main/logic/classes/actions/`
- LWC: `src/main/ui/lwc/`
- Selectors: `src/main/logic/classes/selectors/`
- Object schema: `src/main/schema/objects/`
- Meta XML: API version 65.0, Active status

## Object Rename (v1.2)
Old → New object names (both exist during transition, old to be deleted in cleanup PR):
- `Allowed_Child_Type__c` → `Allowed_Child_Template__c`
- `Project_Template_Work_Item_Type__c` → `Allowed_Work_Item_Template__c`
- `Resource_Type_Template__c` → `Project_Role_Template__c`
- `Template_Action_Config__c` → `Template_Action__c`
- `Template_Field_Config__c` → `Template_Field__c`
- `Template_Status_Config__c` → `Template_Status__c`
- `Time_Entry__c` → `Work_Item_Time_Entry__c`

Renamed selectors: `ResourceTypeTemplateSelector` → `ProjectRoleTemplateSelector`, `TimeEntrySelector` → `WorkItemTimeEntrySelector`
