workspace {

    model {
        
        #Users
        publicUser = person "Public User" "The public users of Book Store." "Public User"
        authorizedUser = person "Authorized User" "The authorized users of Book Store." "Authorized User"
        
        #Main System
        bookStoreSys = softwareSystem "Book Store System" "Support users to manipulate book data." "Main System"{
            #Containers
            publicWebApi = container "Public API Application" "Allows Public users getting books details" "Golang/Memcached-GoClient"
            authorizedWebApis = group "Authorized Web API Applications" {
                searchWebApi = container "Search API Application" "Allows Authorized users to search books" "Golang/Elastic-GoClient"
                adminWebAPI = container "Admin API Application" "Allow Authorized users to manipulate books data" "Golang/Kafka-GoClient" {
                    #Components
                    bookSvc = component "service.Book" "Allow manipulating books details" "Go Rest function"
                    authorizerSvc = component "service.Authorizer" "Authorize users & book details" "Go Rest function"
                    bookEvtPublisher = component "service.EventsPublisher" "Go Rest function/Kafka-GoClient"
                }
            }

            bookDb = container "Book database" "Store book details data" "Postgre" "Database"
            cacheDb = container "Reader Cache database" "Cache book details data" "Memcached" "Database"
            searchDb = container "Search database" "Readonly books data" "ElasticSearch" "Database"

            bookDomainEvt = container "Book Domain Event system" "Handles book-related domain events" "Apache Kafka 3.0"
            elasticEvtConsumer = container "ElasticSearch Events Consumer" "Listening to Kafka domain events and write publisher to Search Database for updating" "Golang/Kafka-GoClient/Elastic-GoClient"
            publisherUpdater = container "Publisher Recurrent Updater" "Listening to external events coming from Publisher System" "Apache Kafka 3.0"
        }

        #External system
        authorizationSys = softwareSystem "Authorization System" "Handle authorization requests." "External System"
        publisherSys = softwareSystem "Publisher System" "Book publisher." "External System"

        #Relationship - #Context
        authorizedUser -> bookStoreSys "Search and Manipulate book details"
        publicUser -> bookStoreSys "Get book details"
        bookStoreSys -> publisherSys "Authorize users by sending request to" {
            tags "Async Request"
        }
        bookStoreSys -> authorizationSys "Update book details by listening events from" {
            tags "Async Request"
        }

        #Relationship - Containers
        publicUser -> publicWebApi "Make API calls to [JSON/HTTPS]"
        publicWebApi -> bookDb "Read from [JDBC]"
        publicWebApi -> cacheDb "Read from and write to [TCP/IP]"

        authorizedUser -> searchWebAPi "Make API calls to [JSON/HTTPS]"
        searchWebApi -> authorizationSys "Make API calls to [JSON/HTTPS]" {
            tags "Async Request"
        }
        searchWebApi -> searchDb "Read data from [JSON/HTTPS]"

        authorizedUser -> adminWebAPI "Make API calls to [JSON/HTTPS]"
        adminWebAPI -> authorizationSys "Make API calls to [JSON/HTTPS]" {
            tags "Async Request"
        }
        adminWebAPI -> bookDb "Read from and write to [JDBC]"
        adminWebAPI -> bookDomainEvt "Publish events to [TCP/IP]"
        elasticEvtConsumer -> bookDomainEvt "Listen to [TCP/IP]"
        elasticEvtConsumer -> searchDb "Write to [JSON/HTTPS]"
        publisherUpdater -> publisherSys "Listen to [TCP/IP]" {
            tags "Async Request"
        }
        publisherUpdater -> adminWebAPI "Make API call to [JSON/HTTP]"

        #Relationship - Components
        authorizedUser -> bookSvc "Make API call to [JSON/HTTPS]"
        bookSvc -> authorizerSvc "Make API call to [JSON/HTTP]"
        authorizerSvc -> authorizationSys "Make API call to [JSON/HTTPS]"
        bookSvc -> bookEvtPublisher "Make API call to [JSON/HTTP]"
        bookEvtPublisher -> bookDomainEvt "Publish events to [TCP/IP]"
        bookSvc -> bookDb "Read from & write to [JDBC]"
    }

    views {
        systemContext bookStoreSys "SystemContext" {
            include *
            autoLayout tb
        }

        container bookStoreSys "Containers" {
            include *
            autoLayout tb
        }

        component adminWebAPI "Components" {
            include *
            autoLayout tb
        }

        styles {
            element "Authorized User" {
                background #08427B
                color #ffffff
                fontSize 22
                shape Person
            }
            element "Public User" {
                background #49be25
                color #ffffff
                fontSize 22
                shape Person
            }
            element "Main System" {
                background #2596be
                color #ffffff
            }

            element "External System" {
                background #999999
                color #ffffff
            }
            
            relationship "Async Request" {
                dashed true
            }
            element "Database" {
                shape Cylinder
            }
        }

        theme default
    }
}