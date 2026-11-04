# 01 — Smart View and connections

## Core idea

Oracle Smart View for Office is an Office add-in used to connect to supported Oracle EPM and other data providers. A user needs the right provider URL, access, client setup, and authentication method configured for their environment.

## Shared versus private connection

| Connection | Simple explanation | Typical configuration |
|---|---|---|
| Shared | A centrally supplied connection entry that an administrator can make available to users | Cloud EPM shared connection URL commonly ends with /workspace/SmartViewProviders |
| Private | A connection saved or entered by an individual user | Planning Cloud private connection commonly ends with /HyperionPlanning/SmartView |

A shared URL can point to administrator-managed connection data. A private connection is user-managed. The exact list of providers available through a shared connection depends on how the administrator configured it.

For Planning Cloud, Oracle documents the private URL pattern /HyperionPlanning/SmartView. Use the actual service URL provided by the Smart View or EPM administrator. Do not substitute an invented production hostname.

## Connect and verify

1. Obtain the connection URL and the target Cloud EPM service/domain from the administrator.
2. Confirm the installed Smart View release and that it is compatible with the organization’s supported Office environment.
3. In Excel, open the Smart View Panel and choose the configured Shared or Private Connections option.
4. Sign in using the organization’s configured authentication flow.
5. Navigate to the intended application and form/ad hoc grid.
6. Verify the provider, application, cube, user, and sheet connection before reading or submitting data.
7. If a connection fails, capture the exact error, time, client version, and diagnostic details before changing settings.

## Security and operational care

- Never place a password in a workbook, VBA macro, screenshot, or support ticket.
- Do not hard-code connection URLs or names without administrator approval.
- A visible connection does not mean the user has rights to every form, member, or cell.
- Do not change proxy, registry, timeout, authentication, or Trust Center settings to guess at a fix. Follow organization IT policy and the current Oracle installation guide.
- Use Smart View Health Check and diagnostics to collect environment information; Health Check is available in Excel.

## Recall check

1. What does a connection URL identify— The route to a configured provider; it does not grant data permissions.
2. Who should provide the actual service URL— The Smart View/EPM administrator.
3. What should be recorded before troubleshooting— The client version, provider, target, error text, time, user context, and relevant diagnostics.

**Teach-back:** Explain the difference between a shared connection entry and a user’s private connection.

## Oracle references

- [URL syntax for Smart View connections](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cgsad/2_working_with_epm_clients_connect_url_syntax.html)
- [Shared and private connections](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/shared_connections_and_private_connections.html)
- [Creating shared connections](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/wsvfg/creating_shared_connections.html)
- [Connecting using a private connection](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/wsvfg/connecting_using_private_connection_102xe5b985f0.html)
- [Smart View 26.100 documentation library](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/)
- [Smart View diagnostics and Health Check](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svuuc/about_smart_view_diagnostics.html)

Smart View 26.100 guides include an October 2026 Developer’s Guide and June 2026 User’s and Installation guides. Checked 2026-10-30; confirm the supported release with your administrator.
